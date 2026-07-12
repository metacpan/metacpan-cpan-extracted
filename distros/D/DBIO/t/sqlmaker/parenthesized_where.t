use strict;
use warnings;

use Test::More;

use DBIO::SQLMaker;
use DBIO::Test;

# DBIO::SQLMaker must emit the canonical, DBIx::Class-style parenthesized
# WHERE clause: 'WHERE ( cond )', not a bare 'WHERE cond'.
#
# This is deliberately checked at the *string* level. is_same_sql (used by
# every other SQL-generation test) normalizes redundant parentheses away, so
# it would NOT notice the outer parens disappearing. The parens are only
# observable in raw SQL and matter where a comparator falls back to literal
# matching (e.g. Oracle CONNECT BY). Without this test the behaviour is
# unguarded and could silently regress.

my $sm = DBIO::SQLMaker->new(quote_char => '"', name_sep => '.');

# select() is the path that lost its parens when the SQLMaker hierarchy was
# renamed away from DBIx::Class::SQLMaker (SQL::Abstract gates its
# parenthesizing select.where renderer on that isa()).
{
  my ($sql) = $sm->select('artist', ['id'], { name => 'foo' });
  like $sql, qr/\bWHERE \s* \( /x,
    'select() single condition: WHERE is parenthesized';
  unlike $sql, qr/\bWHERE \s+ "name"/x,
    'select() does not emit a bare unparenthesized WHERE';
}

{
  my ($sql) = $sm->select('artist', ['id'], { name => 'foo', rank => 1 });
  like $sql, qr/\bWHERE \s* \( /x,
    'select() multiple conditions: WHERE is parenthesized';
}

# End-to-end through a ResultSet (as_query returns \[ $sql, @bind ]).
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  my $aq  = $schema->resultset('Artist')->search({ 'me.name' => 'foo' })->as_query;
  my $sql = $$aq->[0];
  like $sql, qr/\bWHERE \s* \( /x,
    'resultset as_query: WHERE is parenthesized end-to-end';
}

# karr #26 regression: the WHERE clause must carry EXACTLY ONE canonical paren
# layer, never the doubled 'WHERE ( ( ... ) )'. The override in
# DBIO::SQLMaker::new routes the SELECT WHERE through SQL::Abstract::where(),
# which wraps its result in '( ... )'; for an -and/-or top-level node the
# condition was ALREADY wrapped by _render_op_andor, so without the collapse
# the output doubles up. These assertions pin the exact parenthesisation, so
# they FAIL on the doubled form and pass only on the single canonical layer.
# (is_same_sql would normalise the redundant parens away and miss this, which
# is why the whole comparison is at the raw-string level — see ADR 0004.)
{
  my $sm = DBIO::SQLMaker->new(quote_char => '"', name_sep => '.');

  my %where_for = (
    'simple eq'        => { name => 'foo' },
    'compound implicit-and'
                       => { name => 'foo', rank => 1 },
    'explicit -and'    => { -and => [ { name => 'foo' }, { rank => 1 } ] },
    'explicit -or'     => { -or  => [ name => 'foo', name => 'bar' ] },
    'nested group'     => { -or  => [ { -and => [ a => 1, b => 2 ] }, { c => 3 } ] },
    'IN list'          => { id => { -in => [ 1, 2, 3 ] } },
    'BETWEEN (expand_op)'
                       => { cdid => { -between => [ 1, 10 ] } },
    # exact shape reported in karr #26
    'karr #26 shape'   => { -and => [
                              artist => 'x',
                              { cdid  => { -between => [ 1, 10 ] } },
                              { title => { '!=' => 'y' } },
                            ] },
  );

  my %expect_where = (
    'simple eq'             => 'WHERE ( "name" = ? )',
    'compound implicit-and' => 'WHERE ( "name" = ? AND "rank" = ? )',
    'explicit -and'         => 'WHERE ( "name" = ? AND "rank" = ? )',
    'explicit -or'          => 'WHERE ( "name" = ? OR "name" = ? )',
    'nested group'          => 'WHERE ( ( "a" = ? AND "b" = ? ) OR "c" = ? )',
    'IN list'               => 'WHERE ( "id" IN ( ?, ?, ? ) )',
    'BETWEEN (expand_op)'   => 'WHERE ( "cdid" BETWEEN ? AND ? )',
    'karr #26 shape'        => 'WHERE ( "artist" = ? AND ( "cdid" BETWEEN ? AND ? ) AND "title" != ? )',
  );

  for my $name (sort keys %where_for) {
    my ($sql) = $sm->select('artist', ['id'], $where_for{$name});
    my ($got_where) = $sql =~ /(WHERE \s .*) \z/x;
    # Exact-string compare is the regression guard: the doubled
    # 'WHERE ( ( ... ) )' form differs from every expectation below and so
    # fails here. (A 'starts with ( (' heuristic would wrongly flag a
    # legitimate nested group like the one in %expect_where, so we pin the
    # whole clause instead.)
    is $got_where, $expect_where{$name},
      "single canonical WHERE parens: $name";
  }

  # disable_old_special_ops must stay on (ADR 0004): operators above
  # (-in, -between, -ident) only render via expand_op under this flag.
  is $sm->{disable_old_special_ops}, 1,
    'disable_old_special_ops still enabled (operators go through expand_op)';
}

# Adversarial: two sibling parenthesised groups joined at the top level must NOT
# be collapsed — the first '(' does not match the last ')', so the leading layer
# is real, not the redundant one where() added.
{
  my $sm = DBIO::SQLMaker->new(quote_char => '"', name_sep => '.');
  my ($sql) = $sm->select('artist', ['id'], {
    -or => [ { -and => [ a => 1, b => 2 ] }, { -and => [ c => 3, d => 4 ] } ],
  });
  my ($got_where) = $sql =~ /(WHERE \s .*) \z/x;
  is $got_where,
    'WHERE ( ( "a" = ? AND "b" = ? ) OR ( "c" = ? AND "d" = ? ) )',
    'sibling parenthesised groups are preserved, not collapsed';
}

# End-to-end through a ResultSet: a compound WHERE must also keep a single
# canonical paren layer (the path that the dbio-sqlite driver trace caught).
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  my $aq = $schema->resultset('Artist')->search({
    -and => [ { 'me.name' => 'foo' }, { 'me.rank' => 1 } ],
  })->as_query;
  # The whole subquery is itself wrapped in one '( ... )' by as_query; what we
  # pin is that the WHERE inside carries exactly one canonical paren layer.
  is ${$aq}->[0],
    '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield" FROM "artist" "me"'
      . ' WHERE ( "me"."name" = ? AND "me"."rank" = ? ))',
    'resultset compound WHERE: single canonical paren layer end-to-end';
}

done_testing;

use strict;
use warnings;

use Test::More;

# Core ADR 0039 -- the single _set_operation_keyword($op) seam behind all six
# DBIO::ResultSet set operations, as this driver resolves them. OFFLINE: no
# DBI, no DSN, no server. The hook is required to be a static class fact (ADR
# 0039 section 7), so reading it must never touch a handle, and this file would
# hang or die if it did.
#
# PostgreSQL has all six operations in the ANSI spelling, so this driver
# declares NOTHING: it inherits core's base map unchanged and overrides no
# hook. Documented in the PostgreSQL manual, "Combining Queries (UNION,
# INTERSECT, EXCEPT)":
#
#   query1 UNION [ALL] query2
#   query1 INTERSECT [ALL] query2
#   query1 EXCEPT [ALL] query2
#
# -- and the optional ALL is in that grammar in every documented version, back
# to the 7.1 manual, so there is no version boundary for a refusal to be bound
# by. That is why neither ADR 0039 section 7 option applies here: this driver
# has no gap to refuse, conditionally or otherwise.
#
# The file exists anyway, and cheaply: it is the counter-check that core's
# routing change really was byte-identical for a complete engine. Five of the
# six keywords used to be literals in DBIO::ResultSet and now come through the
# storage; a whitespace drift in that move would be invisible to
# is_same_sql_bind's normalisation, so the statements below are compared as
# plain strings.

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::PostgreSQL::Storage;

my @OPS = qw( union union_all intersect intersect_all except except_all );

my %ANSI = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  intersect_all => 'INTERSECT ALL',
  except        => 'EXCEPT',
  except_all    => 'EXCEPT ALL',
);

# --- the six keywords, off the driver class --------------------------------
#
# A class method on a never-instantiated storage: that IS the contract. The
# keyword is baked into a literal from-clause at query-construction time, so a
# hook that needed a $dbh would reintroduce the connect-to-choose-a-word defect
# ADR 0037 removed.

my $pg = DBIO::PostgreSQL::Storage->new;

is $pg->_set_operation_keyword($_), $ANSI{$_},
  "$_ resolves to $ANSI{$_}"
  for @OPS;

is(DBIO::PostgreSQL::Storage->_set_operation_keyword('except'), 'EXCEPT',
  'and it answers as a class method -- no instance, no handle, no probe');

# --- ... because the driver declares nothing --------------------------------
#
# Identity against core's base, not string equality: an override that happened
# to return the same six strings today would still be a second copy of an
# engine fact, free to drift. This assertion is what makes "nothing to declare"
# falsifiable -- if PostgreSQL ever needs an opinion here, this fails first and
# whoever adds it has to say so.

is(DBIO::PostgreSQL::Storage->can('_set_operation_keyword'),
   DBIO::Storage::DBI->can('_set_operation_keyword'),
  'the driver does not override _set_operation_keyword -- it inherits the base map');

# _except_operator is REPLACED by _set_operation_keyword, not deprecated beside
# it (ADR 0039 section 1). An override left behind under the old name is never
# called again and there is no error, so the tripwire is that the name must not
# exist here at all. This driver never had one; the assertion keeps it that way.

ok !DBIO::PostgreSQL::Storage->can('_except_operator'),
  'the superseded _except_operator name is absent, not overridden';

# --- end to end: the keyword reaches the SQL --------------------------------
#
# The hook's return value in isolation would not catch a routing mistake in
# core. These are the statements a PostgreSQL resultset actually builds.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::PostgreSQL::Storage',
  );

  my $left  = $schema->resultset('Artist')
    ->search({ name => 'foo' }, { columns => ['artistid'] });
  my $right = $schema->resultset('Artist')
    ->search({ name => 'bar' }, { columns => ['artistid'] });

  my $operand = 'SELECT "me"."artistid" FROM "artist" "me" WHERE ( "name" = ? )';

  for my $op (@OPS) {
    my ($sql, @bind) = @{ ${ $left->$op($right)->as_query } };

    is $sql,
      qq{(SELECT "me"."artistid" FROM ($operand $ANSI{$op} $operand) "me")},
      "$op joins the two operands with $ANSI{$op}, and nothing else moved";

    is scalar(@bind), 2, "... carrying both operands' bind values";
  }
}

done_testing;

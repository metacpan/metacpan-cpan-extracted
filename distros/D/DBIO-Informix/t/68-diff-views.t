use strict;
use warnings;
use Test::More;

# Offline (karr k25): views in the diff of two models. A view is a table-like
# entry of the model with kind 'view' and the server's CREATE VIEW text as its
# definition (blanks collapsed by the introspector).

use DBIO::Informix::Diff;

sub col { +{ column_name => $_[0], data_type => $_[1] // 'integer', size => $_[2], not_null => 0, default_value => undef, is_pk => 0 } }

sub model {
  my (%m) = @_;
  my %views = %{ $m{views} // {} };
  return {
    tables => {
      ( map { $_ => { table_name => $_, kind => 'table' } } keys %{ $m{columns} } ),
      ( map { $_ => { table_name => $_, kind => 'view', definition => $views{$_} } } keys %views ),
    },
    columns => { %{ $m{columns} }, map { $_ => [ col('id') ] } keys %views },
    indexes => {}, unique_constraints => {}, foreign_keys => {},
  };
}
sub diff { DBIO::Informix::Diff->new(source => $_[0], target => $_[1]) }
sub vdef { my ($n, $from) = @_; qq{CREATE VIEW $n AS SELECT id FROM $from} }

my $base = [ col('id'), col('val', 'varchar', 10) ];

{
  my $d = diff(model(columns => { t => $base }),
               model(columns => { t => $base }, views => { v => vdef('v', 't') }));
  ok $d->has_changes, 'a new view: reported';
  like $d->summary, qr/\bv\b/, '... in the summary';
  is $d->as_sql, vdef('v', 't') . ';', '... CREATE VIEW with the definition, no CREATE TABLE';
}

{
  my $d = diff(model(columns => { t => $base }, views => { v => vdef('v', 't') }),
               model(columns => { t => $base }));
  ok $d->has_changes, 'a view the schema lacks: reported';
  is $d->as_sql, 'DROP VIEW v;', '... DROP VIEW, not DROP TABLE';
}

{
  my $d = diff(model(columns => { t => $base }, views => { v => vdef('v', 't') }),
               model(columns => { t => $base }, views => { v => vdef('v', 't') }));
  ok !$d->has_changes, 'the same definition: no difference';
}

{
  my $d = diff(model(columns => { t => $base }, views => { v => vdef('v', 't') }),
               model(columns => { t => $base }, views => { v => 'CREATE VIEW v AS SELECT id, val FROM t' }));
  ok $d->has_changes, 'a changed definition: reported';
  is $d->as_sql, "DROP VIEW v;\nCREATE VIEW v AS SELECT id, val FROM t;", '... DROP VIEW, then CREATE VIEW';
  is scalar(grep { $_->isa('DBIO::Informix::Diff::Column') } @{ $d->operations }), 0, 'no column operation for a view';
}

{
  my $d = diff(
    model(columns => { t => $base, gone => [ col('id') ] }, views => { old => vdef('old', 't') }),
    model(columns => { t => $base, extra => [ col('id') ] }, views => { n => vdef('n', 'extra') }));
  my @kinds = map { $_->as_sql =~ /^(DROP VIEW|DROP TABLE|CREATE TABLE|CREATE VIEW)/ ? $1 : '?' } @{ $d->operations };
  is_deeply \@kinds, ['DROP VIEW', 'CREATE TABLE', 'DROP TABLE', 'CREATE VIEW'],
    'drop views, then the tables, then create views';
}

{
  my $d = diff(model(columns => { t => $base }),
               model(columns => { t => $base }, views => {
                 a_inner => vdef('a_inner', 't'), b_outer => vdef('b_outer', 'a_inner'),
                 a_outer => vdef('a_outer', 'z_inner'), z_inner => vdef('z_inner', 't') }));
  my @names = map { $_->table_name } grep { $_->isa('DBIO::Informix::Diff::Table') } @{ $d->operations };
  my %at = map { $names[$_] => $_ } 0 .. $#names;
  ok $at{a_inner} < $at{b_outer}, 'created: a view after the view it reads';
  ok $at{z_inner} < $at{a_outer}, '... also against the alphabet';

  my $g = diff(model(columns => { t => $base }, views => { a_inner => vdef('a_inner', 't'), b_outer => vdef('b_outer', 'a_inner') }),
               model(columns => { t => $base }));
  is_deeply [ map { $_->table_name } @{ $g->operations } ], [ 'b_outer', 'a_inner' ],
    'dropped: a view before the view it reads';
}

{
  my $d = diff(model(columns => { v => [ col('id') ] }), model(columns => {}, views => { v => vdef('v', 't') }));
  ok $d->has_changes, 'a table in the database that is a view in the schema: reported';
  ok !eval { $d->as_sql; 1 }, '... and refused (DROP TABLE would take the rows)';
  isa_ok $@, 'DBIO::Exception';
  like "$@", qr/table and view/, '... as a kind change';
  my $r = diff(model(columns => {}, views => { v => vdef('v', 't') }), model(columns => { v => [ col('id') ] }));
  ok !eval { $r->as_sql; 1 }, 'a view that is a table in the schema: refused';
}

{
  my $d = diff(model(columns => { t => $base }), model(columns => { t => $base }, views => { v => undef }));
  ok !eval { $d->as_sql; 1 }, 'a view without a definition cannot be written';
  like "$@", qr/no definition/, '... and says so';
}

done_testing;

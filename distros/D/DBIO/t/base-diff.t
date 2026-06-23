use strict;
use warnings;
use Test::More;

{
  package Test::Op;
  sub new     { bless { sql => $_[1], summary => $_[2] }, $_[0] }
  sub as_sql  { $_[0]->{sql} }
  sub summary { $_[0]->{summary} }

  package Test::Diff;
  use base 'DBIO::Diff::Base';
  sub _build_operations {
    return [ Test::Op->new('ALTER TABLE foo;', '~table: foo') ];
  }
}

my $diff = Test::Diff->new(source => {a => 1}, target => {a => 2});
is $diff->source->{a}, 1, 'source accessor';
is $diff->target->{a}, 2, 'target accessor';
ok $diff->has_changes, 'has_changes true';
is $diff->as_sql, 'ALTER TABLE foo;', 'as_sql delegates to ops';
like $diff->summary, qr/~table: foo/, 'summary delegates to ops';
is $diff->operations, $diff->operations, 'operations cached';

{
  package Empty::Diff;
  use base 'DBIO::Diff::Base';
  sub _build_operations { return [] }
}
ok !Empty::Diff->new(source=>{}, target=>{})->has_changes, 'no ops = no changes';

{
  package Bare::Diff;
  use base 'DBIO::Diff::Base';
}
eval { Bare::Diff->new(source=>{}, target=>{})->operations };
ok $@, '_build_operations not overridden → dies';

done_testing;

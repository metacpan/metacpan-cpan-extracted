use strict;
use warnings;

use Test::More;
use Test::Warn;

use DBIO::Test ':DiffSQL';

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $sql_maker = $schema->storage->sql_maker;

# -nest is deprecated: SQL::Abstract v2 (ClassicExtensions) warns via
# carp_unique, i.e. once per callsite. The loop keeps both passes on the
# same callsite, so pass 1 must warn and pass 2 must stay silent.
for my $pass (1, 2) {
  my ($sql, @bind);
  my $select = sub {
    ($sql, @bind) = $sql_maker->select ('foo', undef, { -nest => \ 'bar' } );
  };

  if ($pass == 1) {
    warnings_like { $select->() }
      [ qr/-nest in search conditions is deprecated/ ],
      'deprecation warning emitted on first call';
  }
  else {
    warnings_are { $select->() } [], 'no deprecation warning on second call (same callsite)';
  }

  is_same_sql_bind (
    $sql, \@bind,
    'SELECT * FROM "foo" WHERE ( bar )', [],
    "-nest still works (pass $pass)"
  );
}

done_testing;

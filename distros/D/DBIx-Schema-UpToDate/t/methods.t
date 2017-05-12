# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::MockObject 1.09;

my $mod = 'DBIx::Schema::UpToDate';
eval "require $mod" or die $@;

my ($table_info, $db_ver);
my $sth = Test::MockObject->new()
  ->mock(fetchall_arrayref => sub { $table_info })
  ->mock(fetchall_hashref  => sub { $table_info });

my @dbh_done;
my ($begun, $committed, $begin, $commit, $do, $dbi_last) = (0, 0, 1, 1, 1, 'unknown');
my $dbh = Test::MockObject->new()
  ->mock(begin_work => sub { $dbi_last = 'begin_work'; ++$begun;     $begin  })
  ->mock(commit     => sub { $dbi_last = 'commit';     ++$committed; $commit })
  ->mock(do         => sub { $dbi_last = 'do ' . ($_[1] =~ /^(\S+)/)[0]; push(@dbh_done, $_[1]); $do })
  ->mock(errstr     => sub { "failure: $dbi_last" })
  ->mock(quote_identifier => sub { qq{"$_[0]"} })
  ->mock(selectcol_arrayref => sub { push(@dbh_done, $_[1]); [$db_ver] })
  ->mock(table_info => sub { $sth });

my $schema = new_ok($mod, [dbh => $dbh, auto_update => 0]);

# current_version
$table_info = [];
is($schema->current_version, undef, 'not built');
$table_info = [version => {}];
$db_ver = 1;
is($schema->current_version, 1, 'version fetched');

# sql_limit
like($dbh_done[-1], qr/DESC LIMIT 1$/, 'used limit');
$schema->{sql_limit} = 0;
is($schema->current_version, 1, 'version fetched');
# limit attribute
like($dbh_done[-1], qr/DESC$/, 'limit not used');
$schema->{sql_limit} = 1;

# latest_version
$schema->{updates} = [1, 2, 3, 4];
is($schema->latest_version, 4, 'fake latest_version');
delete $schema->{updates};
# this one's a little silly
is($schema->latest_version, @{ $schema->updates }, 'latest version');

# up_to_date()
my $updated = 0;
$db_ver = 0;
$schema->{updates} = [sub { $updated++ }, sub { $updated++ }];

$sth->set_series('fetchall_arrayref', [], [1]);
$schema->up_to_date();
is($updated, 2, 'correct number of updates');

$sth->mock('fetchall_arrayref', sub { [1] });

$updated = 0;
$db_ver = 1;
$schema->up_to_date();
is($updated, 1, 'correct number of updates');

$updated = 0;
$db_ver = 2;
$schema->up_to_date();
is($updated, 0, 'correct number of updates');

$sth->set_series('fetchall_arrayref', [], []);
is(eval { $schema->up_to_date(); }, undef, 'up_to_date() dies w/o current version');
like($@, qr/version table/, 'up_to_date() died w/o version table');

# update_to_version transactions
foreach my $test (
  [1, 1],
  [0, 0],
){
  my ($tr, $exp) = @$test;
  $schema->{transactions} = $tr;
  $updated = $begun = $committed = 0;
  $schema->update_to_version(1);
  is($updated,      1, 'updated');
  is($begun,     $exp, "transaction: $tr - begin");
  is($committed, $exp, "transaction: $tr - commit");
}

# DBI errors
{
  $schema->{transactions} = 1;
  $begin = $commit = undef;
  eval { $schema->update_to_version(1) };
  like($@, qr/failure: begin_work/,  'raise begin_work failure');
  $begin = 1;
  eval { $schema->update_to_version(1) };
  like($@, qr/failure: commit/,       'raise commit failure');
  $commit = 1;

  $do = undef;
  eval { $schema->initialize_version_table };
  like($@, qr/failure: do CREATE/, 'raise do() failure');
  eval { $schema->set_version(0) };
  like($@, qr/failure: do INSERT/, 'raise do() failure');

  # reset vars
  $begin = $commit = $do = 1;
}

# update_to_version
my $inst = [0, 0];
$schema->{updates} = [sub { $inst->[0]++ }, sub { $inst->[1]++ }];
$schema->update_to_version(2);
is_deeply($inst, [0,1], 'correct update executed');
$schema->update_to_version(1);
is_deeply($inst, [1,1], 'correct update executed');
$schema->update_to_version(1);
is_deeply($inst, [2,1], 'correct update executed');

done_testing;

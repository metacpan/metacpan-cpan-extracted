# $Id: 08circular_references.t 81 2019-01-30 21:53:22Z stro $

use strict;
use warnings;

use Test::More;
use Cwd;
use File::Spec::Functions;
use File::Path;
use CPAN::DistnameInfo;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestSQL qw($mods $auths $dists has_hash_data);
use CPAN::SQLite::Info;

unless (eval 'use Test::Memory::Cycle; 1;') {
    diag $@;
    plan ('skip_all' => 'Test::Memory::Cycle is required for testing memory leaks');
    exit;
}

use TestShell;

plan tests => 22;

my $cwd      = getcwd;
my $CPAN     = catdir $cwd, 't', 'cpan';
my $db_dir   = catdir $cwd, 't', 'cpan-t-08';
my $log_dir  = $db_dir;
my $filename = 'cpansql.db';
my $filepath = catfile $db_dir, $filename;

unlink $filepath if -e $filepath;
mkdir $db_dir;

ok(-d $CPAN);
use_ok 'CPAN::SQLite::Info';
ok my $info = CPAN::SQLite::Info->new(
  'CPAN'    => $CPAN,
  'db_dir'  => $db_dir,
  'db_name' => $filename,
);
isa_ok($info, 'CPAN::SQLite::Info');

$info->fetch_info();

memory_cycle_ok($info);

use_ok 'CPAN::SQLite::DBI::Index';
ok my $cdbi = CPAN::SQLite::DBI::Index->new(
  CPAN    => $CPAN,
  db_name => $filename,
  db_dir  => $db_dir,
);
isa_ok($cdbi, 'CPAN::SQLite::DBI::Index');

# Check for circular references on Index level
use_ok 'CPAN::SQLite::Index';

my $index = CPAN::SQLite::Index->new(
  'CPAN'    => $CPAN,
  'db_dir'  => $db_dir,
  'db_name' => $filename,
  'setup'   => 1,
);
isa_ok($index, 'CPAN::SQLite::Index');
memory_cycle_ok($index);

ok $index->fetch_info() => 'fetch_info';
memory_cycle_ok($index);

ok $index->populate() => 'populate';
memory_cycle_ok($index);

# Now, that the populate is run, we can run state
# Check for circlular references on State level

use_ok 'CPAN::SQLite::State';
my $state = CPAN::SQLite::State->new(
  db_name => $filename,
  db_dir  => $db_dir,
  CPAN    => $CPAN,
  index   => $index->{'index'},
);
isa_ok($state, 'CPAN::SQLite::State');
$state->state();

memory_cycle_ok($state);

# Check for circular references on Populate level

use_ok 'CPAN::SQLite::Populate';
my $pop = CPAN::SQLite::Populate->new(
  db_name => $filename,
  db_dir  => $db_dir,
  setup   => 1,
  CPAN    => $CPAN,
  index   => $index->{'index'},
);
isa_ok($pop, 'CPAN::SQLite::Populate');
$pop->populate();

memory_cycle_ok($pop);
ok(1);

done_testing();

use Test::More;
use Test::Exception;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

plan skip_all => "Optional module (DB_File) not installed"
  unless eval {
               require DB_File;
              };

my $package = 'Apache::Session::Store::DB_File';

plan tests => 13;

use_ok $package;
use_ok 'DB_File';
can_ok $package, qw[new insert materialize remove];

my $origdir = getcwd;
my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
chdir( $tempdir );

my $serial  = '12345';
my $id      = 'test1';
my $dbfile  = 'foo.dbm';
my $session = {
    serialized => $serial,
    data       => {
                   _session_id => $id,
                  },
    args       => {
                   FileName => $dbfile,
                  },
};

my $store = $package->new;
isa_ok $store, $package;

my $i_ret = $store->insert($session);
is( $i_ret, $serial, "insert() returned value of serialized" );

ok( -e $dbfile, 'dbm file exists' );

undef $store;

$store = $package->new;
isa_ok $store, $package;

$session->{serialized} = undef;
lives_ok {
    $store->materialize($session)
} 'materialize did not die';
is( $session->{serialized}, $serial, "materialized session is correct" );

my $new_serial = 'hi';
$session->{serialized} = $new_serial;
my $u_ret = $store->update($session);
is( $u_ret, $new_serial, "update() returned value of new serialized" );

undef $store;

my %hash;
tie %hash, 'DB_File', $dbfile;

is( $hash{$id}, $new_serial, "dbm file updated correctly" );

$store = $package->new;
isa_ok $store, $package;
$store->remove($session);

dies_ok {
    $store->materialize($session);
} "Can't materialize removed session";

undef $store;
untie %hash;
undef %hash;

chdir( $origdir );

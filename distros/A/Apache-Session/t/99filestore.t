use Test::More;
use Test::Exception;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

plan skip_all => "Optional module (Fcntl) not installed"
  unless eval {
               require Fcntl;
              };

plan tests => 7;

my $package = 'Apache::Session::Store::File';
use_ok $package;

my $origdir = getcwd;
my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
chdir( $tempdir );

my $session = {
    serialized => 12345,
    data => { _session_id => 'test1'},
};

$Apache::Session::Store::File::Directory = '.';
$Apache::Session::Store::File::Directory = '.';

my $store = Apache::Session::Store::File->new;

$store->insert($session);

ok( -e "./test1", "Store file exists" );

undef $store;

open (TEST, '<./test1');

my $store_contents = do { local $/; <TEST> };

ok( $store_contents eq $session->{serialized} && $store_contents == 12345,
    "Store contents are okay" );

close TEST;

$store = Apache::Session::Store::File->new;
$session->{serialized} = '';
$store->materialize($session);

ok( $session->{serialized} == 12345, 'restoring from file worked' );

$session->{serialized} = 'hi';
$store->update($session);
undef $store;

open (TEST, '<./test1');

undef $store_contents;
$store_contents = do { local $/; <TEST> };

ok( $store_contents eq $session->{serialized} && $store_contents eq 'hi',
    'Store contents are okay' );

close TEST;

undef $store;
$store = Apache::Session::Store::File->new;
$store->remove($session);

ok( !-e "./test1", 'Session removed properly' );

dies_ok {
    $store->materialize($session);
} "could not materialize nonexistent session";    

chdir( $origdir );

use Test::More;
use Test::Deep;
use Test::Exception;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

plan skip_all => "Optional module (Fcntl) not installed"
  unless eval {
               require Fcntl;
              };

plan tests => 9;

my $package = 'Apache::Session::File';
use_ok $package;

my $origdir = getcwd;
my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
chdir( $tempdir );

my %session;
my %tie_params = (
    Directory     => '.',
    LockDirectory => '.'
);

tie %session, $package, undef, { %tie_params };

ok( tied(%session), "session is tied" );

ok(  exists($session{_session_id}), "session id exists" );
ok( defined($session{_session_id}), "session id is defined" );

my $id = $session{_session_id};

my $foo = 'bar';
my $baz = [ qw[tom dick harry] ];

$session{foo} = $foo;
$session{baz} = $baz;

untie %session;
undef %session;

tie %session, $package, $id, { %tie_params };

ok( tied(%session), "The session is tied again" );

is( $session{_session_id}, $id, "Session IDs match" );

cmp_deeply $session{foo}, $foo, "Foo matches";
cmp_deeply $session{baz}, $baz, "Baz matches";

tied(%session)->delete;
untie %session;
undef %session;

dies_ok {
    tie %session, $package, '../../../../../../../../foo', { %tie_params };
} "unsafe tie detected correctly";

chdir( $origdir );

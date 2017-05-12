use Test::More;
use Test::Deep;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

plan skip_all => "Optional module (DB_File) not installed"
  unless eval {
               require DB_File;
              };

my $package = 'Apache::Session::DB_File';

plan tests => 8;

use_ok $package;

my $origdir = getcwd;
my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
chdir( $tempdir );

my %session;
my %tie_params = (
    FileName      => './text.db',
    LockDirectory => '.',
);

tie %session, $package, undef, { %tie_params };

ok( tied(%session), "The session is tied" );

ok(  exists($session{_session_id}), "Session id exists"     );
ok( defined($session{_session_id}), "Session id is defined" );

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

chdir( $origdir );

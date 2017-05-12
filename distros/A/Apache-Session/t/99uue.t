use Test::More;
use Test::Deep;
use Test::Exception;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

#plan skip_all => "Optional module (Storable) not installed"
#  unless eval {
#               require Storable;
#              };

plan tests => 2;

my $package = 'Apache::Session::Serialize::UUEncode';
use_ok $package;

my $origdir = getcwd;
my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
chdir( $tempdir );

my $serial = \&Apache::Session::Serialize::UUEncode::serialize;
my $unserial = \&Apache::Session::Serialize::UUEncode::unserialize;

my $session = {
    serialized => undef,
    data       => undef,
};
my $simple  = {
    foo  => 1,
    bar  => 2,
    baz  => 'quux',
    quux => ['foo', 'bar'],
};

$session->{data} = $simple;

&$serial($session);

$session->{data} = undef;

&$unserial($session);

cmp_deeply($simple, $session->{data}, 'session data is correct');

chdir( $origdir );

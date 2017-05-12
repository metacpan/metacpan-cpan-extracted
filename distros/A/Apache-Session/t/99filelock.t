use Test::More;
use Test::Exception;
use File::Temp qw[tempdir];
use Cwd qw[getcwd];

plan skip_all => "Optional module (Fcntl) not installed"
  unless eval {
               require Fcntl;
              };

plan tests => 4;

my $package = 'Apache::Session::Lock::File';
use_ok $package;

my $origdir = getcwd;
my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
chdir( $tempdir );

my $lock    = $package->new;
my $session = {
    data => { _session_id   => 'foo' },
    args => { LockDirectory => '.'   },
};

$lock->acquire_read_lock($session);

ok -e './Apache-Session-foo.lock', 'lock file exists';

undef $lock;

unlink('./Apache-Session-foo.lock');

$lock = $package->new;

$lock->acquire_write_lock($session);

ok -e './Apache-Session-foo.lock', 'lock file exists';

$lock->release_all_locks($session);


$lock->clean('.', 0);

ok !-e './Apache-Session-foo.lock', 'lock file does not exist';

chdir( $origdir );

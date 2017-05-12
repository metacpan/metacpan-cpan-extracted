use strict;
use Test::More;
#use Test::Exception;
use File::Temp qw[tempdir];
#use Cwd qw[getcwd];
use Config;

BEGIN {
 plan skip_all => "semget not implemented" unless $Config{d_semget};
 #Darwin may not have semaphores, see
 #http://sysnet.ucsd.edu/~bellardo/darwin/sysvsem.html
 plan skip_all => "semctl not implemented" unless $Config{d_semctl};
 plan skip_all => "Can't tune this test. Help needed.";
 
 plan skip_all => "Optional modules (IPC::SysV, IPC::Semaphore) not installed"
  unless eval {
               require IPC::SysV;
               require IPC::Semaphore;
              };
 plan skip_all => "Cygserver is not running"
  if $^O eq 'cygwin' && (!exists $ENV{'CYGWIN'} || $ENV{'CYGWIN'} !~ /server/i);
}

plan tests => 33;

my $package = 'Apache::Session::Lock::Semaphore';
use_ok $package;

#my $origdir = getcwd;
#my $tempdir = tempdir( DIR => '.', CLEANUP => 1 );
#chdir( $tempdir );

use IPC::SysV qw(IPC_CREAT S_IRWXU SEM_UNDO);
use IPC::Semaphore;
diag("IPC::Semaphore version $IPC::Semaphore::VERSION");

my $semkey = int(rand(2**15-1));

my $session = {
    data => {_session_id => 'foo'},
    args => {SemaphoreKey => $semkey}    
};

my $number = 1;
for my $iter (2,4,6,8) {
    $session->{args}->{NSems} = $iter;
    my $locker = $package->new($session);
    
    isa_ok $locker, $package;

    $locker->acquire_read_lock($session);
    my $semnum = $locker->{read_sem};
    ok(defined($semnum),'$locker->{read_sem} is defined');

    my $sem = IPC::Semaphore->new($semkey, $number++, S_IRWXU);
    diag("NSems: $iter, error: $!") unless defined($sem);

    isa_ok $sem, 'IPC::Semaphore';

    my @sems = $sem->getall;

    ok $sems[$semnum] == 1 && $sems[$semnum+$iter/2] == 0,
       'the semaphores seem right';

    $locker->acquire_write_lock($session);

    @sems = $sem->getall;

    ok $sems[$semnum] == 0 && $sems[$semnum+$iter/2] == 1,
       'semaphores seem right again';

    $locker->release_write_lock($session);
    
    @sems = $sem->getall;

    ok $sems[$semnum] == 0 && $sems[$semnum+$iter/2] == 0,
       'the semaphores seem right x3';

    $locker->acquire_write_lock($session);
    $locker->release_all_locks($session);
    
    @sems = $sem->getall;

    ok $sems[$semnum] == 0 && $sems[$semnum+$iter/2] == 0,
       'the semaphores seem right x4';

    $locker->acquire_read_lock($session);
    $locker->release_all_locks($session);
    
    @sems = $sem->getall;

    ok $sems[$semnum] == 0 && $sems[$semnum+$iter/2] == 0,
       'the semaphores seem right x5';

    $sem->remove;
}

#chdir( $origdir );

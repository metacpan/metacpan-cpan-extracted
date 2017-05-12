use Test::Most;
use Path::Tiny;
use Time::HiRes qw(usleep);
use File::Slurp;

{

    package Test::Daemon;
    use Moose;
    with 'App::Base::Daemon::Supervisor';
    use File::Slurp;
    use Time::HiRes qw(usleep);

    has tmp_dir => (
        is       => 'ro',
        required => 1,
    );

    sub documentation {
        return 'this is a test daemon';
    }

    sub supervised_shutdown {
        my $self = shift;
        my $file = $self->tmp_dir . "/shutdown";
        my $num  = -r $file ? read_file($file) : '0';
        $num++;
        write_file($file, $num);
    }

    sub supervised_process {
        my $self     = shift;
        my $pid_file = $self->tmp_dir->child('pid');
        write_file($pid_file, $$);
        while (1) {
            usleep 100_000;
            $self->ping_supervisor;
        }
    }
}

my $tmp_dir = Path::Tiny->tempdir(CLEANUP => 0);

local $ENV{APP_BASE_DAEMON_PIDDIR} = $tmp_dir;
my $superpid_file = $tmp_dir->child('Test::Daemon.pid');
my $pid_file      = $tmp_dir->child('pid');
my $shutdown_file = $tmp_dir->child('shutdown');

note "Test::Daemon should start supervisor process which should start a supervised child";
is(
    Test::Daemon->new({
            tmp_dir              => $tmp_dir,
            delay_before_respawn => 0.1,
        }
        )->run,
    0,
    "Test daemon deamonized"
);
usleep(500_000);
chomp(my $pid = read_file($superpid_file));
ok $pid, "Have read daemon PID";
ok(kill(ZERO => $pid), "Supervisor process is running");
my $cpid = read_file($pid_file);
ok $cpid, "Supervised process is running";
isnt $pid, $cpid, "   and it is not the same as supervisor";

note "if we kill supervised process with TERM, it should execute supervised_shutdown";
ok(kill(TERM => $cpid), "Sent TERM to the child");
my $count = 20;
while (kill(ZERO => $cpid) and $count--) {
    usleep(50_000);
}
ok(!kill(ZERO => $cpid), "Child exited");
kill KILL => $cpid;    # in case it didn't
is(read_file($shutdown_file), "1", "Child executed supervised_shutdown before exit");

note "supervisor should fork another child after previous one exited";
$count = 10;
while (read_file($pid_file) eq $cpid and $count--) {
    usleep(50_000);
}
my $old_cpid = $cpid;
$cpid = read_file($pid_file);
isnt $old_cpid, $cpid, "new child has been started";

kill KILL => $pid;
kill KILL => $cpid;

done_testing;

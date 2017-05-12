use Benchmark;
use Apache::Session::Lock::MySQL;

use vars qw($s $dbh);

$s = {
    args => {
        LockDataSource => 'dbi:mysql:database=test;host=desk.eng.vivaldi',
        LockUsername   => 'jwb',
        LockPassword   => ''
    },
    data => {
        _session_id => ''
    }
};

$dbh = DBI->connect('dbi:mysql:database=test;host=desk.eng.vivaldi', 'jwb', '', {RaiseError => 1});

sub loop {
    $s->{data}->{_session_id} = int(rand(2**20));
    my $l = new Apache::Session::Lock::MySQL;
    $l->acquire_read_lock($s);
    $l->acquire_write_lock($s);
}

timethis(1000, \&loop, 'Connect 1000 Times');

$s->{args}->{LockHandle} = $dbh;

timethis(10000, \&loop, 'Connect Once, Lock 10000 Times');

`mkfifo sync`;

for ($n = 10; $n <= 100; $n += 10) {
    $dbh->disconnect;

    my $is_child;
    for (my $i = 0; $i < $n - 1; $i++) {
        my $pid = fork;

        if (!$pid) {
            $is_child = 1;
            open (SYNC, ">sync") || die $!;
            last;
        }
    }

    if (!$is_child) {
        print "Sleeping 2 seconds to sync children\n";
        sleep 2;
        open(GO, "<sync") || die $!;
    }

    $dbh = DBI->connect('dbi:mysql:database=test;hostname=desk.eng.vivaldi', 'jwb', '', {RaiseError => 1});
    $s->{args}->{LockHandle} = $dbh;
    timethis(-1, \&loop, "$n Children");

    if ($is_child) {
        exit();
    }

    for (my $i = 0; $i < $n - 1; $i++) {
        wait();
    }

    close GO;
}

unlink "sync";

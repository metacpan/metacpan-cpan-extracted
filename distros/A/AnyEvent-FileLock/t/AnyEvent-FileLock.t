# -*- Mode: cperl -*-

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('AnyEvent::FileLock') };

use AE;
use Fcntl;
use File::Temp qw(tempfile);

subtest 'file handle as locking target' => sub {
    my $cv = AE::cv();
    my $temp_fh = tempfile();
    my $got_lock;
    my $w = AnyEvent::FileLock->flock(
        fh => $temp_fh,
        cb => sub {
            if (defined (my $fh = shift)) {
                $got_lock = 1;
                close $fh;
            }
            $cv->send();
        },
    );
    $cv->recv();
    ok($got_lock, 'got lock');

    done_testing();
};

subtest 'retry to get lock' => sub {
    my $cv = AE::cv();
    my ($temp_fh, $filename) = tempfile();
    flock($temp_fh, Fcntl::LOCK_EX|Fcntl::LOCK_NB);

    my $got_lock;
    my $w = AnyEvent::FileLock->flock(
        file => $filename,
        cb   => sub {
            if (defined (my $fh = shift)) {
                $got_lock = 1;
                close $fh;
            }
            $cv->send();
        },
    );
    my $t = AE::timer(0.3, 0, sub { flock($temp_fh, Fcntl::LOCK_UN); });
    $cv->recv();
    ok($got_lock, 'got lock');
    is_deeply($w, {}, 'object emptied');

    done_testing();
};

subtest 'abort after timeout' => sub {
    my $cv = AE::cv();
    my ($temp_fh, $filename) = tempfile();
    flock($temp_fh, Fcntl::LOCK_EX|Fcntl::LOCK_NB);

    my $got_lock = 0;
    my $start_time = AE::now;
    my $end_time;
    my $w = AnyEvent::FileLock->flock(
        file    => $filename,
        timeout => 1,
        cb      => sub {
            if (defined (my $fh = shift)) {
                $got_lock = 1;
                close $fh;
            }
            $end_time = AE::now;
            $cv->send();
        },
    );
    $cv->recv();
    ok(!$got_lock, 'got no lock');
    cmp_ok($start_time + 0.5, '<', $end_time, 'waited for more than 0.5s');
    close($temp_fh);

    done_testing();
};

use strict;
use warnings;
use Test::More;
use POSIX ();
use File::Temp qw(tempdir);
use Time::HiRes qw(time);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $dir = tempdir(CLEANUP => 1);
for my $kind (['Str', 'Data::ReqRep::Shared', 'Data::ReqRep::Shared::Client', 'x', [4, 64, 16]],
              ['Int', 'Data::ReqRep::Shared::Int', 'Data::ReqRep::Shared::Int::Client', 1, [4, 64]]) {
    my ($name, $sc, $cc, $msg, $geom) = @$kind;
    my $p = "$dir/$name.shm";
    my $srv = $sc->new($p, @$geom);
    my $cap = $srv->capacity;
    my $end = time + 3;
    my @kids;
    for my $role (qw(send send recv)) {
        my $pid = fork // die $!;
        if (!$pid) {
            if ($role eq 'send') {
                my $c = $cc->new($p);
                my @ids;
                while (time < $end) {
                    my $id = $c->send($msg);
                    if (defined $id) { push @ids, $id } else { $c->cancel(shift @ids) for 1 .. (@ids > 50 ? 50 : @ids) }
                }
            }
            else { while (time < $end) { my @r = $srv->recv } }
            POSIX::_exit(0);
        }
        push @kids, $pid;
    }
    my $mon = $cc->new($p);
    my ($n, $over, $max) = (0, 0, 0);
    while (time < $end) {
        my $s = $mon->size;
        $n++;
        next unless $s > $cap;
        $over++;
        $max = $s if $s > $max;
    }
    waitpid $_, 0 for @kids;
    is $over, 0, "$name: size never exceeds the capacity of $cap under traffic ($n reads, max seen $max)";
}

done_testing;

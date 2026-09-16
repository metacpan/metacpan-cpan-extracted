use strict;
use warnings;
use Test::More;
use POSIX ();

# The batch methods (set_multi, remove_multi, get_multi) evaluate their key and
# value arguments with SvIV/SvPV, which runs a tied scalar's FETCH or an
# overloaded object's conversion.  Those must run before the map's lock is
# taken: a FETCH that re-enters the same map with a write, while the batch holds
# the write lock (set_multi/remove_multi) or the read lock (get_multi), would
# self-deadlock the whole map -- our own live pid sits in the lock word, so
# every other process on the map hangs too.  The fix materialises every argument
# before the lock.
#
# The probe runs in a child under a no-handler alarm: a regression is a signal
# death, not a hung suite, since a Perl alarm cannot interrupt an XSUB spinning
# in C.

{
    package ReenterKey;
    sub TIESCALAR { my ($c, $m, $k2, $v, $k1) = @_;
                    bless { m => $m, k2 => $k2, v => $v, k1 => $k1, n => 0 }, $c }
    sub FETCH { my $s = shift;
                $s->{m}->put($s->{k2}, $s->{v}) unless $s->{n}++;   # re-enter with a write
                $s->{k1} }
}

sub in_child {
    my ($code) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) { $SIG{ALRM} = 'DEFAULT'; alarm 8; eval { $code->() }; POSIX::_exit($@ ? 2 : 0) }
    waitpid $pid, 0;
    return ($? & 127) ? 'hung' : ($? >> 8) == 0 ? 'ok' : 'died';
}

# [ class, key1, key2, value ] -- valid literals for each key/value type.
my @variants = (
    [ 'II',   1,   2,   9   ],
    [ 'IS',   1,   2,   'x' ],
    [ 'SI',   'a', 'b', 9   ],
    [ 'SS',   'a', 'b', 'x' ],
    [ 'I16',  1,   2,   9   ],
    [ 'I32',  1,   2,   9   ],
    [ 'I16S', 1,   2,   'x' ],
    [ 'I32S', 1,   2,   'x' ],
    [ 'SI16', 'a', 'b', 9   ],
    [ 'SI32', 'a', 'b', 9   ],
);

for my $v (@variants) {
    my ($cls, $k1, $k2, $val) = @$v;
    my $class = "Data::HashMap::Shared::$cls";
    eval "require $class; 1" or die $@;

    for my $method (qw(set_multi remove_multi get_multi)) {
        is in_child(sub {
            my $m = $class->new(undef, 256);
            tie my $tk, 'ReenterKey', $m, $k2, $val, $k1;
            if    ($method eq 'set_multi')    { $m->set_multi($tk, $val) }
            elsif ($method eq 'remove_multi') { $m->put($k1, $val); $m->remove_multi($tk) }
            else                              { $m->get_multi($tk) }
        }), 'ok', "$cls $method: a re-entrant magical key completes, no deadlock";
    }
}

done_testing;

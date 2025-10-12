package MHFS::FD::Reader v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Time::HiRes qw( usleep clock_gettime CLOCK_MONOTONIC);
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use Scalar::Util qw(looks_like_number weaken);
sub new {
    my ($class, $process, $fd, $func) = @_;
    my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'process' => $process, 'fd' => $fd, 'onReadReady' => $func);
    say "PID " . $self{'process'}{'pid'} . 'FD ' . $self{'fd'};
    weaken($self{'process'});
    return bless \%self, $class;
}

sub onReadReady {
    my ($self) = @_;
    my $ret = $self->{'onReadReady'}($self->{'fd'});
    if($ret == 0) {
        $self->{'process'}->remove($self->{'fd'});
        return 1;
    }
    if($ret == -1) {
        return undef;
    }
    if($ret == 1) {
        return 1;
    }
}

sub onHangUp {

}

sub DESTROY {
    my $self = shift;
    print "PID " . $self->{'process'}{'pid'} . ' ' if($self->{'process'});
    print "FD " . $self->{'fd'};
    say ' reader DESTROY called';
}

1;

package MHFS::FD::Writer v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Time::HiRes qw( usleep clock_gettime CLOCK_MONOTONIC);
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use Scalar::Util qw(looks_like_number weaken);
sub new {
    my ($class, $process, $fd, $func) = @_;
    my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'process' => $process, 'fd' => $fd, 'onWriteReady' => $func);
    say "PID " . $self{'process'}{'pid'} . 'FD ' . $self{'fd'};
    weaken($self{'process'});
    return bless \%self, $class;
}

sub onWriteReady {
    my ($self) = @_;
    my $ret = $self->{'onWriteReady'}($self->{'fd'});
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
    say "PID " . $self->{'process'}{'pid'} . " FD " . $self->{'fd'}.' writer DESTROY called';
}

1;

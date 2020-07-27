package Command::Runner::Timeout;
use strict;
use warnings;
use Time::HiRes ();

sub new {
    my ($class, $at, $kill) = @_;
    my $now = Time::HiRes::time();
    bless { signaled => 0, at => $now + $at, at_kill => $now + $at + $kill }, $class;
}

sub signal {
    my $self = shift;
    return if !$self->{at} && !$self->{at_kill};
    my $now = Time::HiRes::time();
    if ($self->{at} and $now >= $self->{at}) {
        $self->{at} = undef;
        $self->{signaled} = 1;
        return 'TERM';
    }
    if ($now >= $self->{at_kill}) {
        $self->{at_kill} = undef;
        $self->{signaled} = 1;
        return 'KILL';
    }
    return;
}

sub signaled {
    my $self = shift;
    $self->{signaled};
}

1;

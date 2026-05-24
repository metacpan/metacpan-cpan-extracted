package App::RemoteCommand::Pool;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

sub new ($class) {
    bless {
        pool => [],
    }, $class;
}

sub all ($self) {
    $self->{pool}->@*;
}

sub add ($self, $ssh) {
    push $self->{pool}->@*, $ssh;
    $self;
}

sub remove ($self, $ssh) {

    for my $i (0..$self->{pool}->$#*) {
        if ($self->{pool}[$i] eq $ssh) {
            return splice $self->{pool}->@*, $i, 1;
        }
    }
    return;
}

sub count ($self) {
    scalar $self->{pool}->@*;
}

1;

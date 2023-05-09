package App::RemoteCommand::Pool;
use v5.16;
use warnings;

sub new {
    my $class = shift;
    bless {
        pool => [],
    }, $class;
}

sub all {
    my $self = shift;
    @{$self->{pool}};
}

sub add {
    my ($self, $ssh) = @_;
    push @{$self->{pool}}, $ssh;
    $self;
}

sub remove {
    my ($self, $ssh) = @_;

    for my $i (0..$#{$self->{pool}}) {
        if ($self->{pool}[$i] eq $ssh) {
            return splice @{$self->{pool}}, $i, 1;
        }
    }
    return;
}

sub count {
    my $self = shift;
    scalar @{$self->{pool}};
}

1;

package App::RemoteCommand::Pool;
use strict;
use warnings;
use IO::Select;

sub new {
    my $class = shift;
    bless {
        pool => [],
        select => IO::Select->new,
    }, $class;
}

sub select :method {
    my $self = shift;
    $self->{select};
}

sub all {
    my $self = shift;
    @{$self->{pool}};
}

sub add {
    my ($self, $cmd) = @_;
    push @{$self->{pool}}, $cmd;
    $self->{select}->add($cmd->fh) if $cmd->fh;
    $self;
}

sub find {
    my ($self, $k, $v) = @_;
    my @found = grep { defined $_->$k and $_->$k eq $v } @{$self->{pool}};
    $found[0];
}

sub remove {
    my ($self, $k, $v) = @_;
    for my $i (0..$#{$self->{pool}}) {
        if (defined $self->{pool}[$i]->$k and $self->{pool}[$i]->$k eq $v) {
            my $remove = splice @{$self->{pool}}, $i, 1;
            $self->{select}->remove($remove->fh) if $remove->fh;
            return $remove;
        }
    }
    return;
}

sub remove_all {
    my $self = shift;
    $self->{pool} = [];
    $self->{select} = IO::Select->new;
}

sub count {
    my $self = shift;
    scalar @{$self->{pool}};
}

1;

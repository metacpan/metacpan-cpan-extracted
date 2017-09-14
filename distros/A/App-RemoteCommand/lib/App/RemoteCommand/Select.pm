package App::RemoteCommand::Select;
use strict;
use warnings;
use IO::Select;
use App::RemoteCommand::LineBuffer;

sub new {
    my $class = shift;
    bless { select => IO::Select->new, container => [] }, $class;
}

sub add {
    my ($self, %args) = @_;
    my $pid = $args{pid};
    my $fh = $args{fh};
    my $host = $args{host};
    my $buffer = $args{buffer} || App::RemoteCommand::LineBuffer->new;
    push @{$self->{container}}, {
        pid => $pid,
        fh => $fh,
        host => $host,
        buffer => $buffer,
    };
    $self->{select}->add($fh);
}

sub can_read {
    my $self = shift;
    my @fh = $self->{select}->can_read(@_);
    my @ready;
    for my $c (@{$self->{container}}) {
        if (grep { $c->{fh} == $_ } @fh) {
            push @ready, $c;
        }
    }
    return @ready;
}

sub count {
    my $self = shift;
    $self->{select}->count;
}

sub remove {
    my ($self, $kind, $value) = @_;
    for my $i (0..$#{$self->{container}}) {
        if ($self->{container}[$i]{$kind} eq $value) {
            my $remove = splice @{$self->{container}}, $i, 1;
            $self->{select}->remove($remove->{fh});
            return $remove;
        }
    }
    return;
}

1;

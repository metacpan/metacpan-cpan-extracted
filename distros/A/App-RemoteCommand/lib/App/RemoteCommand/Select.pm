package App::RemoteCommand::Select;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use IO::Select;
use App::RemoteCommand::LineBuffer;

sub new ($class) {
    bless { select => IO::Select->new, container => [] }, $class;
}

sub add ($self, %args) {
    my $pid = $args{pid};
    my $fh = $args{fh};
    my $host = $args{host};
    my $buffer = $args{buffer} || App::RemoteCommand::LineBuffer->new;
    push $self->{container}->@*, {
        pid => $pid,
        fh => $fh,
        host => $host,
        buffer => $buffer,
    };
    $self->{select}->add($fh);
}

sub can_read ($self, @args) {
    my @fh = $self->{select}->can_read(@args);
    my @ready;
    for my $c ($self->{container}->@*) {
        if (grep { $c->{fh} == $_ } @fh) {
            push @ready, $c;
        }
    }
    return @ready;
}

sub count ($self) {
    $self->{select}->count;
}

sub remove ($self, $kind, $value) {
    for my $i (0..$self->{container}->$#*) {
        if ($self->{container}[$i]{$kind} eq $value) {
            my $remove = splice $self->{container}->@*, $i, 1;
            $self->{select}->remove($remove->{fh});
            return $remove;
        }
    }
    return;
}

1;

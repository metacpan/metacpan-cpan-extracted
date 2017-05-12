package DBGp::Client::AsyncStream;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        socket  => $args{socket},
        buffer  => '',
        on_line => undef,
    }, $class;

    return $self;
}

sub on_line { $_[0]->{on_line} = $_[1] }

sub add_data {
    my ($self, $bytes) = @_;

    $self->{buffer} .= $bytes;

    while (defined(my $line = $self->_try_line)) {
        $self->{on_line}->($line);
    }
}

sub put_line {
    my ($self, @items) = @_;
    my $cmd = join(" ", @items);

    syswrite $self->{socket}, $cmd . "\x00";
}

sub _try_line {
    my ($self) = @_;
    my $buffer = \$self->{buffer};

    my $len_end = index($$buffer, "\x00");
    return if $len_end == -1;

    my $len = 0 + substr $$buffer, 0, $len_end;
    return if length($$buffer) < $len_end + $len + 2;

    die "Packat is not null-terminated"
        unless substr($$buffer, $len_end + $len + 1, 1) eq "\x00";

    my $line = substr $$buffer, $len_end + 1, $len;
    substr $$buffer, 0, $len_end + $len + 2, '';

    return $line;
}

1;

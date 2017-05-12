package DBGp::Client::Stream;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        socket  => $args{socket},
        buffer  => '',
    }, $class;

    return $self;
}

sub get_line {
    my ($self) = @_;
    my $buffer = \$self->{buffer};

    my $len_end = index($$buffer, "\x00");
    while ($len_end == -1) {
        return undef
            if read($self->{socket}, $$buffer, 2, length($$buffer)) == 0;

        $len_end = index($$buffer, "\x00");
    }

    my $len = substr $$buffer, 0, $len_end;
    substr $$buffer, 0, $len_end + 1, '';

    if (length($$buffer) < $len + 1) {
        return undef
            if read($self->{socket}, $$buffer, $len + 1 - length($$buffer), length($$buffer)) == 0;
    }

    die "Short read"
        if length($$buffer) < $len + 1;
    die "Packat is not null-terminated"
        unless substr($$buffer, $len, 1, '') eq "\x00";

    return substr $$buffer, 0, $len, '';
}

sub put_line {
    my ($self, @items) = @_;
    my $cmd = join(" ", @items);

    syswrite $self->{socket}, $cmd . "\x00";
}

1;

package AWS::XRay::Buffer;

use 5.012000;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ($sock, $auto_flush) = @_;
    bless {
        buf        => [],
        sock       => $sock,
        auto_flush => $auto_flush,
    }, $class;
}

sub flush {
    my $self = shift;
    my $sock = $self->{sock};
    for my $buf (@{ $self->{buf} }) {
        $sock->syswrite($buf, length($buf));
    }
    $self->{buf} = [];
    1;
}

sub close {
    my $self = shift;
    $self->{buf} = [];
    1;
}

sub print {
    my $self = shift;
    my $data = join("", @_);
    if ($self->{auto_flush}) {
        $self->{sock}->syswrite($data, length($data));
    }
    else {
        push @{ $self->{buf} }, $data;
    }
}

1;

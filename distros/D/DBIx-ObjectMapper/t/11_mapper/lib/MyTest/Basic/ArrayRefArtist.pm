package MyTest::Basic::ArrayRefArtist;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless \@_, $class;
}

sub id {
    my $self = shift;
    $self->[0] = shift if @_;
    return $self->[0];
}

sub firstname {
    my $self = shift;
    $self->[1] = shift if @_;
    return $self->[1];
}

sub lastname {
    my $self = shift;
    $self->[2] = shift if @_;
    return $self->[2];
}

1;

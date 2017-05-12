package MyTest::Basic::GenericAccessorArtist;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $attr = shift;
    bless { params => \%$attr }, $class;
}

sub get {
    my ( $self, $name ) = @_;
    return $self->{params} unless $name;
    return $self->{params}{$name};
}

sub set {
    my ( $self, $name, $val ) = @_;
    return $self->{params}{$name} = $val;
}

1;

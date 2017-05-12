package Config::Layered::Source;
use warnings;
use strict;

# Parent Class

sub new {
    my ( $class, $layered, $args ) = @_;
    my $self = bless { layered => $layered, args => $args }, $class;
    return $self;
}

sub get_config {
    my ( $self ) = @_;

    return {};
}

sub layered {
    return shift->{layered};
}

sub args {
    return shift->{args};
}

1;

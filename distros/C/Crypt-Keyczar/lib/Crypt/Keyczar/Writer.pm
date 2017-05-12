package Crypt::Keyczar::Writer;
use strict;
use warnings;
use Carp;


sub new {
    my $class = shift;
    my $location = shift;
    my $self = bless { location => undef }, $class;
    $self->location($location);
    return $self;
}


sub location {
    my $self = shift;
    $self->{location} = shift if @_;
    return $self->{location};
}


sub put_metadata {
    croak "Please override, 'Crypt::Keyczar::Writer' is abstract class";

    my $self = shift;
    my $meta = shift;
}


sub put_key {
    croak "Please override, 'Crypt::Keyczar::Writer' is abstract class";

    my $self = shift;
    my ($version, $key) = @_;
}


sub delete_key {
    croak "Please override, 'Crypt::Keyczar::Writer' is abstract class";

    my $self = shift;
    my $version = shift;
}

1;
__END__

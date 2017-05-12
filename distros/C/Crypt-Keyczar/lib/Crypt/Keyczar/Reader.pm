package Crypt::Keyczar::Reader;
use strict;
use warnings;
use Carp;


sub new {
    croak "Please override, 'Crypt::Keyczar::Reader' is abstract class";

    my $class = shift;
    my $location = shift;
    return bless {
        location => $location
    }, $class;
}


sub get_key {
    croak "Please override, 'Crypt::Keyczar::Reader' is abstract class";
    my $self = shift;
    my $version = shift;

    my $json_key = undef;
    return $json_key;
}


sub get_metadata {
    croak "Please override, 'Crypt::Keyczar::Reader' is abstract class";

    my $self = shift;
    my $json_metadata = undef;
    return $json_metadata;
}

1;
__END__

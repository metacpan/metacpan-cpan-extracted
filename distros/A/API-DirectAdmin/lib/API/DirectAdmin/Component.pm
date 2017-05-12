# Constructor class for API-DirectAdmin components

package API::DirectAdmin::Component;

use Modern::Perl '2010';
use Carp;

our $VERSION = 0.02;

sub new {
    my ( $class, %params ) = @_;
    $class = ref $class || $class;

    confess "Required API::DirectAdmin object!" unless $params{directadmin};

    return bless \%params, $class;
}

# API::DirectAdmin object
sub directadmin { $_[0]->{directadmin} }

1;

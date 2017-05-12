package Catmandu::Adlib::API::Login;

our $VERSION = '0.02';

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use base 'LWP::UserAgent';

has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);

# login => moet helemaal anders!

sub get_basic_credentials {
    my ($self, $realm, $url) = @_;
    return $self->username, $self->password;
}

1;
__END__
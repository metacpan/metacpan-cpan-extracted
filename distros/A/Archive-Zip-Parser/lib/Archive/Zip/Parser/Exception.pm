package Archive::Zip::Parser::Exception;

use warnings;
use strict;
use Carp;

sub _croak {
    my ( $self, $error_message ) = @_;
    my $caller_package = (caller)[0];

    croak "[$caller_package] $error_message";
}

1;

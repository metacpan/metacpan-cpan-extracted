package Apertur::SDK::Error::Authentication;

use strict;
use warnings;
use parent 'Apertur::SDK::Error';

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(
        status_code => 401,
        code        => 'AUTHENTICATION_FAILED',
        message     => $args{message} // 'Authentication failed',
    );
}

1;

__END__

=head1 NAME

Apertur::SDK::Error::Authentication - 401 authentication error

=head1 DESCRIPTION

Thrown when the API returns a 401 status code, indicating that the
provided API key or OAuth token is invalid or missing.

=cut

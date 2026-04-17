package Apertur::SDK::Error::Validation;

use strict;
use warnings;
use parent 'Apertur::SDK::Error';

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(
        status_code => 400,
        code        => 'VALIDATION_ERROR',
        message     => $args{message} // 'Validation error',
    );
}

1;

__END__

=head1 NAME

Apertur::SDK::Error::Validation - 400 validation error

=head1 DESCRIPTION

Thrown when the API returns a 400 status code, indicating that the
request payload failed validation.

=cut

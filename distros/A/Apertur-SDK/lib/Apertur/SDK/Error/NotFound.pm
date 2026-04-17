package Apertur::SDK::Error::NotFound;

use strict;
use warnings;
use parent 'Apertur::SDK::Error';

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(
        status_code => 404,
        code        => 'NOT_FOUND',
        message     => $args{message} // 'Not found',
    );
}

1;

__END__

=head1 NAME

Apertur::SDK::Error::NotFound - 404 not found error

=head1 DESCRIPTION

Thrown when the API returns a 404 status code, indicating that the
requested resource does not exist.

=cut

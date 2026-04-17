package Apertur::SDK::Error::RateLimit;

use strict;
use warnings;
use parent 'Apertur::SDK::Error';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(
        status_code => 429,
        code        => 'RATE_LIMIT',
        message     => $args{message} // 'Rate limit exceeded',
    );
    $self->{retry_after} = $args{retry_after};
    return $self;
}

sub retry_after { return $_[0]->{retry_after} }

1;

__END__

=head1 NAME

Apertur::SDK::Error::RateLimit - 429 rate limit error

=head1 DESCRIPTION

Thrown when the API returns a 429 status code, indicating that the
request rate limit has been exceeded.

=head1 METHODS

=over 4

=item B<retry_after>

Returns the number of seconds to wait before retrying, or C<undef>
if the server did not provide a Retry-After header.

=back

=cut

package Apertur::SDK::Resource::Encryption;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub get_server_key {
    my ($self) = @_;
    return $self->{http}->request('GET', '/api/v1/encryption/server-key');
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Encryption - Encryption key retrieval

=head1 DESCRIPTION

Retrieves the server's RSA public key used for end-to-end encrypted
image uploads.

=head1 METHODS

=over 4

=item B<get_server_key()>

Returns a hashref containing the server's RSA public key in PEM format
(C<publicKey> field).

=back

=cut

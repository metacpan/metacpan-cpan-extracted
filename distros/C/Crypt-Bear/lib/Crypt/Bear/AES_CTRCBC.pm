package Crypt::Bear::AES_CTRCBC;
$Crypt::Bear::AES_CTRCBC::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: AES CTRCBC class for BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::AES_CTRCBC - AES CTRCBC class for BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $aead = Crypt::Bear::CCM->new(Crypt::Bear::AES_CTRCBC->new($key));

=head1 DESCRIPTION

This creates a new AES in CTRCBC mode object. This is primarily useful when combined with L<CCM|Crypt::Bear::CCM> or L<EAX|Crypt::Bear::EAX>.

=head1 METHODS

=head2 new($key)

This initializes a new AES_CTRCBC object with C<$key>. C<$key> much be appropriately sized for AES (16, 24, or 32 bytes).

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::Bear::X509::Certificate;
$Crypt::Bear::X509::Certificate::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;
use Crypt::Bear::PEM;

sub load {
	my ($class, $filename) = @_;

	open my $fh, '<:crlf', $filename or die "Could not open certificate $filename: $!";
	my $raw = do { local $/; <$fh> };
	my ($banner, $content) = Crypt::Bear::PEM::pem_decode($raw);
	die "File $filename does not contain a certificate" unless $banner =~ /CERTIFICATE/;

	return $class->new($content);
}

1;

# ABSTRACT: A X509 certificate in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::X509::Certificate - A X509 certificate in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $chain = Crypt::Bear::X509::Certificate->load($filename);

=head1 DESCRIPTION

This represents a single certificate.

=head1 METHODS

=head2 new($encoded)

This decodes a certificate into an object.

=head2 load($filename)

This loads a certificate from the given file, and returns it as a new object.

=head2 dn()

The (encoded) distinguished name of the certificate.

=head2 public_key()

The public key of the certificate. This will either be a L<Crypt::Bear::RSA::PublicKey> or a L<Crypt::Bear::EC::PublicKey>.

=head2 is_ca()

True if the certificate is marked as a CA.

=head2 signer_key_type()

The type of the signer's key, C<'rsa'> or C<'ec'>.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

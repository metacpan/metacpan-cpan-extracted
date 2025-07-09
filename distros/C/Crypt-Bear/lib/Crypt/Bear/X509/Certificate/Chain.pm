package Crypt::Bear::X509::Certificate::Chain;
$Crypt::Bear::X509::Certificate::Chain::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;
use Crypt::Bear::PEM;

sub load {
	my ($class, $filename) = @_;

	my $self = $class->new;

	open my $fh, '<:crlf', $filename or die "Could not open certificate $filename: $!";
	my $raw = do { local $/; <$fh> };
	my (@items) = Crypt::Bear::PEM::pem_decode($raw);

	while (my ($banner, $content) = splice @items, 0, 2) {
		die "File $filename does not contain a certificate" unless $banner =~ /CERTIFICATE/;
		my $cert = Crypt::Bear::X509::Certificate->new($content);
		$self->add($cert);
	}

	return $self;
}

1;

#ABSTRACT: A certificate chain for BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::X509::Certificate::Chain - A certificate chain for BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $chain = Crypt::Bear::X509::CertificateChain->load($filename);

=head1 DESCRIPTION

This represents a certificate chain, from the end-user certificate to the root CA, potentially including intermediate CAs in between, or only one certificate if it's self-signed.

=head1 METHODS

=head2 new()

This creates a new empty certificate chain.

=head2 load($filename)

This class methods loads a certificate file, and creates a new certificate chain with all the certificates in the file in it.

=head2 add($certificate)

This adds a certificate to the chain.

=head2 count()

This return the number of certificates in the chain.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::Bear::SSL::PrivateCertificate;
$Crypt::Bear::SSL::PrivateCertificate::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;

use Crypt::Bear::X509::Certificate::Chain;
use Crypt::Bear::X509::PrivateKey;

1;

sub load {
	my ($class, $chain_file, $key_file, @extra) = @_;
	my $chain = Crypt::Bear::X509::Certificate::Chain->load($chain_file);
	my $key = Crypt::Bear::X509::PrivateKey->load($key_file);

	return $class->new($chain, $key, @extra);
}

1;

# ABSTRACT: a Certificate Chain and Private key combination for BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::SSL::PrivateCertificate - a Certificate Chain and Private key combination for BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $priv_cert = Crypt::Bear::SSL::PrivateCertificate->load('server.crt', 'server.key');
 my $server = Crypt::Bear::SSL::Server->new($priv_cert);

=head1 DESCRIPTION

This repressents the pair of Certificate Chain and Private key, used to established secure connections.

=head1 METHODS

=head2 new($certificate, $key)

This creates a new L<certificate chain|Crypt::Bear::X509::Certificate::Chain> L<private key|Crypt::Bear::X509::PrivateKey> pair.

=head2 load($certificate_file, $key_file)

This loads the C<$certificate_file> and C<$key_file>, and creates a new object out of them.

=head2 chain()

This returns the certificate chain in this object.

=head2 key()

This return the private key in this object.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

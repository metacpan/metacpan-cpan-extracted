package Crypt::Bear::X509::PrivateKey;
$Crypt::Bear::X509::PrivateKey::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;
use Crypt::Bear::PEM;

sub load {
	my ($class, $filename) = @_;

	open my $fh, '<:crlf', $filename or die "Could not open certificate $filename: $!";
	my $raw = do { local $/; <$fh> };
	my ($banner, $content) = Crypt::Bear::PEM::pem_decode($raw);
	die "File $filename does not contain a private key" unless $banner =~ /PRIVATE KEY/;

	return $class->new($content);
}

1;

#ABSTRACT: A X509 private key

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::X509::PrivateKey - A X509 private key

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $private_key = Crypt::Bear::X509::PrivateKey->load($filename);

=head1 DESCRIPTION

This represents a X509 private key.

#ABSTRACT: A X509 private key

=head1 METHODS

=head2 new($payload)

This decodes an encoded private key

=head2 load($filename)

This loads an encoded private key from a file.

=head2 unpack()

This will return the underlaying key. This will either be a L<Crypt::Bear::RSA::PrivateKey> or a L<Crypt::Bear::EC::PrivateKey>.

=head2 type()

The type of the key, either C<'rsa'> or C<'ec'>.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

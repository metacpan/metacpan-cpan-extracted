package Crypt::Passphrase::SHA1::Hex;
$Crypt::Passphrase::SHA1::Hex::VERSION = '0.021';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Validator';

use Digest::SHA 'sha1';

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub accepts_hash {
	my ($self, $hash) = @_;
	return $hash =~ / ^ [a-f0-9]{40} $/xi;
}

sub verify_password {
	my ($self, $password, $hash) = @_;
	return sha1($password) eq pack 'H40', $hash;
}

1;

# ABSTRACT: Validate against hexed SHA1 hashes with Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::SHA1::Hex - Validate against hexed SHA1 hashes with Crypt::Passphrase

=head1 VERSION

version 0.021

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder    => 'Argon2',
     validators => [ 'SHA1::Hex' ],
 );

=head1 DESCRIPTION

This module implements a validator for base64-encoded SHA-1 hashes.

This has no configuration and will try to match any value that looks like 20 bytes encoded in hex.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

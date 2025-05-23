package Crypt::Passphrase::MD5::Base64;
$Crypt::Passphrase::MD5::Base64::VERSION = '0.021';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Validator';

use Digest::MD5 'md5';
use MIME::Base64 'decode_base64';

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub accepts_hash {
	my ($self, $hash) = @_;
	return $hash =~ m{ ^ [A-Za-z0-9+/]{22} (?:==)? $ }x;
}

sub verify_password {
	my ($self, $password, $hash) = @_;
	my $new_hash = md5($password);
	return $new_hash eq decode_base64($hash);
}

1;

# ABSTRACT: Validate against base64ed MD5 hashes with Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::MD5::Base64 - Validate against base64ed MD5 hashes with Crypt::Passphrase

=head1 VERSION

version 0.021

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder    => 'Bcrypt',
     validators => [ 'MD5::Base64' ],
 );

=head1 DESCRIPTION

This module implements a validator for base64-encoded MD5 hashes.

This has no configuration and will try to match any value that looks like 16 bytes encoded in base64.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::Passphrase::MD5::Hex;
$Crypt::Passphrase::MD5::Hex::VERSION = '0.006';
use parent 'Crypt::Passphrase::Validator';

use Digest::MD5 'md5_hex';

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub accepts_hash {
	my ($self, $hash) = @_;
	return $hash =~ / ^ [A-Fa-f0-9]{32} $/x;
}

sub verify_password {
	my ($self, $password, $hash) = @_;
	return md5_hex($password) eq $hash;
}

1;

# ABSTRACT: Validate against hexed MD5 hashes with Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::MD5::Hex - Validate against hexed MD5 hashes with Crypt::Passphrase

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This module implements a validator for hex-encoded MD5 hashes.

=head1 METHODS

=head2 new()

This creates a new MD5 validator. It takes no arguments.

=head2 accepts_hash($hash)

This (heuristically) determines if we may be dealing with a hex encoded md5 sum.

=head2 verify_hash($password, $hash)

This determines if the password matches the hash when MD5'ed.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::Yescrypt;
$Crypt::Yescrypt::VERSION = '0.004';
use strict;
use warnings;

use XSLoader;
XSLoader::load('Crypt::Yescrypt');

use Exporter 5.57 'import';
our @EXPORT_OK = qw(yescrypt yescrypt_check yescrypt_needs_rehash yescrypt_kdf);

1;

# ABSTRACT: A Perl interface to the yescrypt password hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Yescrypt - A Perl interface to the yescrypt password hash

=head1 VERSION

version 0.004

=head1 DESCRIPTION

yescrypt is a password-based key derivation function (KDF) and password hashing scheme. It builds upon Colin Percival's scrypt. This implementation is able to compute native yescrypt hashes as well as classic scrypt.

=head2 Why yescrypt?

Like it or not, password authentication remains relevant (including as one of several authentication factors), password hash database leaks happen, the leaks are not always detected and fully dealt with right away, and even once they are many users' same or similar passwords reused elsewhere remain exposed. To mitigate these risks (as well as those present in other scenarios where password-based key derivation or password hashing is relevant), computationally expensive (L<bcrypt|Crypt::Bcrypt>, L<PBKDF2|Crypt::PBKDF2>, etc.) and more recently also memory-hard (L<scrypt|Crypt::ScryptKDF>, L<Argon2|Crypt::Argon2>, etc.) password hashing schemes have been introduced. Unfortunately, at high target throughput and/or low target latency their memory usage is unreasonably low, up to the point where they're not obviously better than the much older bcrypt (considering attackers with pre-existing hardware). This is a primary drawback that yescrypt addresses.

Most notable for large-scale deployments is yescrypt's optional initialization and reuse of a large lookup table, typically occupying at least tens of gigabytes of RAM and essentially forming a site-specific ROM. This limits attackers' use of pre-existing hardware such as botnet nodes.

yescrypt's other changes from scrypt additionally slow down GPUs and to a lesser extent FPGAs and ASICs even when its memory usage is low and even when there's no ROM, and provide extra knobs and built-in features.

=head1 FUNCTIONS

=head2 yescrypt($password, $salt, $flags, $block_count, $block_size, $parallelism = 1, $time = 0, $upgrades = 0)

This function processes the $password with the given $salt and parameters. It encodes the resulting tag and the parameters as a password string (e.g. C<$y$j9T$SALT$HIA0o5.HmkE9HhZ4H8X1r0aRYrqdcv0IJEZ2PLpqpz6>).

=head2 yescrypt_check($password, $hash)

This verifies that the C<$password> matches C<$hash>. All parameters and the tag value are extracted from C<$hash>, so no further arguments are necessary.

=head2 yescrypt_needs_rehash($hash, $salt, $flags, $block_count, $block_size, $parallelism, $time, $upgrades)

This returns true if the yescrypt C<$hash> uses a different parameters than the given parameters.

=head2 yescrypt_kdf($password, $salt, $output_size, $flags, $block_count, $block_size, $parallelism = 1, $time = 0, $upgrades = 0)

This function processes the $password with the given $salt and parameters. It returns only the hash, without parameters or encoding.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

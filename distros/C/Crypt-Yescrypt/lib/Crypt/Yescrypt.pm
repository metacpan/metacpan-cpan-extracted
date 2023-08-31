package Crypt::Yescrypt;
$Crypt::Yescrypt::VERSION = '0.003';
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

version 0.003

=head1 DESCRIPTION

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

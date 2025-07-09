package Crypt::Bear::PRNG;
$Crypt::Bear::PRNG::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: A baseclass for PRNGs in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::PRNG - A baseclass for PRNGs in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 $prng->system_seed;
 say unpack 'H*', $prng->generate(16);

=head1 DESCRIPTION

This is a base class for cryptographically secure pseudo random number generators. At the moment there are two of such implemented in this distribution: L<Crypt::Bear::HMAC_DRBG> and L<Crypt::Bear::AES_DRBG>.

=head1 METHODS

=head2 generate($length)

This method produces C<$length> pseudorandom bytes and returns them. The context is updated accordingly.

=head2 system_seed()

This feeds entropy from the system, returning true on success. In almost any cryptographic use either calling this or seeding it with an appropriate amount of entropy is essential for safe operation of the PRNG.

This is known to be supported on Linux, BSD, Mac, Windows, AIX and Solaris, as well as any x86 platform when compiling with gcc/clang.

=head2 system_seeder_name()

The name of the system seeder, or C<'none'> if none is available.

=head2 update($data)

Inject additional seed bytes. The provided seed bytes are added into the PRNG internal entropy pool.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

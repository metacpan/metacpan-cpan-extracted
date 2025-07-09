package Crypt::Bear::Hash;
$Crypt::Bear::Hash::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: hash implementations in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::Hash - hash implementations in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $digester = Crypt::Bear::Hash->new('sha226');
 while(<>) {
     $digester->update($_);
 }
 say unpack 'H*', $digester->out;

=head1 DESCRIPTION

This represents a streaming implementation of common hash functions.

=head1 METHODS

=head2 new($digest)

This creates a new hasher. The digest name must be one of the following.

=over 4

=item * C<'md5'>

=item * C<'sha1'>

=item * C<'sha224'>

=item * C<'sha256'>

=item * C<'sha384'>

=item * C<'sha512'>

=back

=head2 update(data)

Add some more bytes to the hash computation represented by the provided context.

=head2 out()

This returns the hash based on the current state. The context is NOT modified by this operation, so this function can be used to get a "partial hash" while still keeping the possibility of adding more bytes to the input.

=head2 state()

Get a copy of the "current state" for the computation so far. For MD functions (MD5, SHA-1, SHA-2 family), this is the running state resulting from the processing of the last complete input block.

=head2 set_state($state)

Set the internal state to the provided values. C<$state> shall match that which was obtained from C<state()>. This restores the hash state only if the state values were at an appropriate block boundary.

=head2 output_size()

The size of the output of this hash.

=head2 digest()

Returns the digest name for this hash.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

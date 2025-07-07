package Crypt::Sodium::XS::MemVault;
use strict;
use warnings;

use Crypt::Sodium::XS;

use overload (
  fallback => 0,
  nomethod => \&_overload_nomethod,
  bool => \&_overload_bool,
  "!" => \&_overload_bool,
  eq => \&_overload_eq,
  ne => \&_overload_ne,
  '""' => \&_overload_str,
  x => \&_overload_mult,
  '.' => \&_overload_concat,
  '.=' => \&concat,
  cmp => \&compare,
  '<=>' => \&compare,
  '^' => \&_overload_xor,
  '^=' => \&xor,
);

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::MemVault - Protected memory objects

=head1 SYNOPSIS

  use Crypt::Sodium::XS::MemVault;

  ...

=head1 DESCRIPTION

=head1 CONSTRUCTORS

=head2 new

  my $mv = Crypt::Sodium::XS::MemVault->new($bytes, $flags);

C<$flags> is optional (default:
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>).

=head2 new_from_hex

  my $mv = Crypt::Sodium::XS::MemVault->new_from_hex($bytes, $flags);

C<$flags> is optional (default:
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>).

=head2 new_from_base64

  my $mv
    = Crypt::Sodium::XS::MemVault->new_from_base64($base64, $variant, $flags);

C<$variant> is optional (default:
L<Crypt::Sodium::XS::Base64/BASE64_VARIANT_URLSAFE_NO_PADDING>). See
L<Crypt::Sodium::XS::Base64/CONSTANTS>.

C<$flags> is optional (default:
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>).

=head2 new_from_file

  my $mv = Crypt::Sodium::XS::MemVault->new_from_file($path, $flags);

C<$flags> is optional (default:
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>).

=head2 new_from_fd

  my $mv = Crypt::Sodium::XS::MemVault->new_from_fd(fileno($fh), $flags);

B<Note>: this requires the file descriptor number, not a perl file handle.

C<$flags> is optional (default:
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>).

=head1 METHODS

=head2 is_locked

  my $is_locked = $mv->is_locked;

Returns a boolean indicating if the object is conceptually "locked."

=head2 clone

  my $new_mv = $mv->clone;

Returns a new object C<$new_mv> with identical contents to the original C<$mv>.

=head2 concat

  my $new_mv = $mv->concat($bytes);
  my $new_mv = $mv->concat($other_mv);

Returns a new object with the concatenated contents of C<$mv> followed by
C<$bytes> or the contents of C<$other_mv>.

=head2 compare

  $mv->compare($bytes, $length);
  $mv->compare($other_mv, $length);

Fixed-time (for a given length) comparison of bytes as little-endian
arbitrary-length integers. Returns C<0> if the bytes are equal, C<-1> if C<$mv>
is less than C<$other_mv> (or C<$bytes>), or C<1> if C<$mv> is greater.
Comparible to the C<cmp> perl operator.

C<$length> is optional iif C<$mv> and C<$other_mv> (or C<$bytes>) are equal
lengths. If provided, only C<$length> bytes are compared.

=head2 flags

  my $flags = $mv->flags;
  $mv->flags($new_flags);

Return or set memory protection flags. See
L<Crypt::Sodium::XS::ProtMem/MEMORY SAFETY>.

=head2 from_base64

  # shortcut for Crypt::Sodium::XS::MemVault->new_from_base64($mv, ..);
  my $new_mv = $mv->from_base64($variant, $flags);

C<$variant> is optional (default:
L<Crypt::Sodium::XS::Base64/BASE64_VARIANT_URLSAFE_NO_PADDING>). See
L<Crypt::Sodium::XS::BASE64/CONSTANTS>.

C<$flags> is optional. If not provided, the new MemVault will use the same
flags as the one from which it is created.

Stops parsing at the first non-base64 byte (valid characters depend on
C<$variant>). C<$new_mv> will be empty if the data cannot be parsed as valid
base64 (i.e., the output would not be a multiple of 8 bits).

=head2 from_hex

  # shortcut for Crypt::Sodium::XS::MemVault->new_from_hex($mv, ..);
  my $new_mv = $mv->from_hex($flags);

C<$flags> is optional. If not provided, the new MemVault will use the same
flags as the one from which it is created.

Stops parsing at the first non-hex ([0-9a-f] case insensitive) byte.

=head2 index

  my $pos = $mv->index($substr, $offset);

B<WARNING>: this method does B<NOT> run in constant-time!

Searches for an occurence of C<$substr> in protected memory. This is similar to
perl's own index function. Returns the first match of C<$substr> at or after
C<$offset>, or -1 if C<$substr> is not found.

C<$offset> is optional. If not provided, the search will begin at the start of
the protected memory. Unlike perl's index function, C<$offset> may not be
negative, and the method will croak if offset is beyond the last byte of
protected memory.

This method should only be used when protected memory starts with non-sensitive
data, and is guaranteed to find C<$substr> before any sensitive data.

=head2 is_zero

  my $is_null = $mv->is_zero;

Returns a boolean indicating if the protected memory consists of all null
bytes. Runs in constant time for a given length.

=head2 length

  my $length = $mv->length;

Returns the byte length of the protected memory. Runtime does not depend on
data.

=head2 lock

  $mv->lock;

Conceptually "lock" the object. This prevents access to the protected memory
from perl (e.g., the object cannot be stringified, and attempting to do so will
croak).

=head2 memcmp

  $mv->memcmp($bytes, $length);
  $mv->memcmp($other_mv, $length);

Fixed-time (for a given length) comparison of bytes as little-endian
arbitrary-length integers. Returns true if the bytes are equal, false
otherwise.

C<$length> is optional iif C<$mv> and C<$other_mv> (or C<$bytes>) are equal
lengths. If provided, only C<$length> bytes are compared.

=head2 to_fd

  $mv->to_fd(fileno($fh));
  close($fh) or die "error: $!";

Returns number of bytes written. Croaks on failure.

=head2 to_file

  $mv->to_file($path);

Returns number of bytes written. Croaks on failure.

=head2 to_base64

  my $new_mv = $mv->to_base64($variant);

Returns a new L<Crypt::Sodium::XS::MemVault> with the contents encoded in
base64.

C<$variant> is optional (default:
L<Crypt::Sodium::XS::Base64/BASE64_VARIANT_URLSAFE_NO_PADDING>). See
L<Crypt::Sodium::XS::Base64/CONSTANTS>.

=head2 to_hex

  my $new_mv = $mv->to_hex;

Returns a new L<Crypt::Sodium::XS::MemVault> with the contents encoded as a
hexadecimal string.

=head2 unlock

  $mv->unlock;

Conceptually "unlock" the object. This allows access to the protected memory
from perl (e.g., the object can be stringified).

=head2 memzero

  $mv->memzero;

Overwrites protected memory with null bytes.

You may not need to call this yourself; unless using both of the non-default
flags L<Crypt::Sodium::XS::ProtMem/PROTMEM_FLAGS_MALLOC_PLAIN> and
L<Crypt::Sodium::XS::ProtMem/PROTMEM_FLAGS_MEMZERO_DISABLED> (or
L<Crypt::Sodium::XS::ProtMem/PROTMEM_ALL_DISABLED>), the memory is zeroed when
the object is destroyed.

=head2 xor

  $mv->xor($bytes);
  $mv->xor($other_mv);

Modifies protected memory using the exclusive-or operation with the provided
argument. The argument must be the same number of bytes in length as the
protected memory.

=head1 OVERLOADS

=head2 boolean

  my $is_empty = !$mv;
  my $is_not_empty = !!$mv;

=head2 eq

  my $is_equal = $mv eq $bytes;
  my $is_equal = $bytes eq $mv;
  my $is_equal = $mv eq $other_mv;

=head2 ne

  my $not_equal = $mv ne $bytes;
  my $not_equal = $bytes ne $mv;
  my $not_equal = $mv ne $other_mv;

=head2 stringification

  my $var = "$mv";

Stringifying a MemVault will croak if it is conceptually "locked."

=head2 concatenation

  my $new_mv = $mv . $string;
  my $new_mv = $string . $mv;
  my $new_mv = $mv . $other_mv;

C<.=> is equivalent to L</concat>.

=head2 repetition

  my $new_mv = $mv x 3;

=head2 exclusive or

  my $new_mv = $mv ^ $bytes;
  my $new_mv = $bytes ^ $mv;
  my $new_mv = $mv ^ $other_mv;

C<^=> is equivalent to L</xor>.

=head1 FEEDBACK

For reporting bugs, giving feedback, submitting patches, etc. please use the
following:

=over 4

=item *

IRC channel C<#sodium> on C<irc.perl.org>.

=item *

Email the author directly.

=back

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

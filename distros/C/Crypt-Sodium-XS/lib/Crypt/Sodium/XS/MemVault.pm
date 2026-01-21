package Crypt::Sodium::XS::MemVault;
use strict;
use warnings;

use Crypt::Sodium::XS;

use Exporter 'import';
use Fcntl qw(
  F_GETFD F_SETFD
  O_CREAT O_NOCTTY O_RDONLY O_RDWR O_TRUNC O_WRONLY
);

our %EXPORT_TAGS = (
  constructors => [qw[
    mv_new
    mv_from_base64
    mv_from_hex
    mv_from_fd
    mv_from_file
    mv_from_tty
    mv_from_tty_file
    mv_from_ttyno
  ]],
);
$EXPORT_TAGS{all} = [ @{$EXPORT_TAGS{constructors}} ];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

use overload (
  fallback => 0,
  nomethod => \&_overload_nomethod,
  bool => \&_overload_bool,
  "!" => \&_overload_bool,
  eq => \&_overload_eq,
  '==' => \&_overload_eq,
  'ne' => \&_overload_ne,
  '!=' => \&_overload_ne,
  '""' => \&to_bytes,
  x => \&_overload_mult,
  '.' => \&concat,
  '.=' => \&concat_inplace,
  cmp => \&compare,
  '<=>' => \&compare,
  '>' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) == 1 },
  'gt' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) == 1 },
  '>=' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) != -1 },
  'ge' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) != -1 },
  '<' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) == -1 },
  'lt' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) == -1 },
  '<=' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) != 1 },
  'le' => sub { ($_[2] ? compare($_[1], $_[0]) : compare($_[0], $_[1])) != 1 },
  '&' => \&bitwise_and,
  '&=' => \&bitwise_and_equals,
  '|' => \&bitwise_or,
  '|=' => \&bitwise_or_equals,
  '^' => \&bitwise_xor,
  '^=' => \&bitwise_xor_equals,
);

sub mv_new { __PACKAGE__->new(@_); }
sub mv_from_base64 { __PACKAGE__->new_from_base64(@_); }
sub mv_from_hex { __PACKAGE__->new_from_hex(@_); }
sub mv_from_fd { __PACKAGE__->new_from_fd(@_); }
sub mv_from_file { __PACKAGE__->new_from_file(@_); }
sub mv_from_tty { __PACKAGE__->new_from_tty(@_); }
sub mv_from_ttyno { __PACKAGE__->new_from_ttyno(@_); }

sub new_from_file {
  my $invocant = shift;
  my $path = shift;
  $path = '' unless defined $path;
  sysopen(my $fh, $path, O_NOCTTY|O_RDONLY)
    or die "$path: new_from_file:open: $!";
  return $invocant->new_from_fd(fileno($fh), @_);
}

my $tty_init = eval 'Fcntl::O_TTY_INIT()';
$tty_init = 0 if !defined($tty_init);
sub new_from_tty {
  my $invocant = shift;
  # undef intended to indicate 'controlling tty'
  my $path = shift;
  $path = '/dev/tty' unless defined $path;
  sysopen(my $fh, $path, O_NOCTTY|O_RDWR|$tty_init)
    or die "$path: new_from_tty:open: $!";
  return $invocant->new_from_ttyno(fileno($fh), @_);
}

sub to_file {
  my $invocant = shift;
  my $path = shift;
  $path = '' unless defined $path;
  my $mode = shift;
  $mode = 0600 unless defined $mode;
  sysopen(my $fh, $path, O_CREAT|O_NOCTTY|O_TRUNC|O_WRONLY, $mode)
    or die "$path: to_file:open: $!";
  return $invocant->to_fd(fileno($fh), @_);
}

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::MemVault - Protected memory objects

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  use Crypt::Sodium::XS::MemVault ':constructors';

  my $key = Crypt::Sodium::XS->generichash->keygen;
  # keygen returns a Crypt::Sodium::XS::MemVault
  $key->to_file("/some/path");
  print "hex: ", $key->to_hex->unlock, "\n";
  print "base64: ", $key->to_base64->unlock, "\n";

  my $key2 = mv_from_file("/other/path");

  if ($key1->memcmp($key2)) {
    die "randomly generated key matches loaded key: inconceivable!";
  }

  my $mv = mv_new("hello");

  my $extracted_data_mv = $mv->extract(1, 3); # "ell"
  print $extracted_data_mv->unlock, "\n";
  undef $extracted_data_mv;

  $mv->unlock;
  my $mv2 = $mv->clone; # unlocked clone is unlocked
  $mv2->xor_equals("\x{1f}\x{0a}\x{1e}\x{00}\x{0b}");
  print "$mv, $mv2!\n";
  my $colon_idx = $mv->index('ll'); # 2
  my $unlocked_mv = $mv->clone;
  $mv->lock;

=head1 DESCRIPTION

L<Crypt::Sodium::XS::MemVault> is the container for protected memory objects in
L<Crypt::Sodium::XS> which can be accessed from perl. It has constructors which
can read in the sensitive data without going through perl. It also provides
methods for manipulating the data while it remains only in protected memory.
These methods (except L</index>) are time-dependent only on the size of
protected data, not its content, so using them should not create any
sidechannels.

Memory protections are documented in L<Crypt::Sodium::XS::ProtMem>.

=head1 CONSTRUCTORS

=head2 new

  my $mv = Crypt::Sodium::XS::MemVault->new($bytes, $flags);

C<$bytes> is an arbitrary string of bytes.

C<$flags> is optional. It is the L<flags|Crypt::Sodium::XS::ProtMem/FLAGS> of
the newly-created MemVault object. If not provided, the default is
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>.

Returns a L<Crypt::Sodium::XS::MemVault>: the content of C<$bytes>.

=head2 new_from_hex

  my $mv = Crypt::Sodium::XS::MemVault->new_from_hex($hex_string, $flags);

C<$hex_string> is an arbitrary length string. Decoding of C<$hex_string> will
stop at the first non-hex character.

C<$flags> is optional. If not provided, the default is
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decoded content of
C<$hex_string>.

=head2 new_from_base64

  my $mv
    = Crypt::Sodium::XS::MemVault->new_from_base64($base64, $variant, $flags);

C<$base64> is an arbitrary length string. Decoding of C<$base64> will stop at
the first non-base64 character.

C<$variant> is optional. If not provided, the default is
L<Crypt::Sodium::XS::Base64/BASE64_VARIANT_URLSAFE_NO_PADDING>. See
L<Crypt::Sodium::XS::Base64/CONSTANTS>.

C<$flags> is optional. It is the L<flags|Crypt::Sodium::XS::ProtMem/FLAGS> of
the newly-created MemVault object. If not provided, the default is
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decoded content of C<$base64>.

=head2 new_from_file

  my $mv = Crypt::Sodium::XS::MemVault->new_from_file($path, $size, $flags);

C<$path> is a filesystem path.

C<$size> is optional. It is the B<maximum> number of bytes to read from C<$fd>.
If not provided or it numifies to 0, C<$fd> will be read until end-of-file.

C<$flags> is optional. It is the L<flags|Crypt::Sodium::XS::ProtMem/FLAGS> of
the newly-created MemVault object. If not provided, the default is
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>.

Returns a L<Crypt::Sodium::XS::MemVault>: the bytes read from the file located
at C<$path>, B<up to> C<$size> bytes or until end-of-file if C<$size> is 0.

Croaks on failure to open or read C<$path>.

=head2 new_from_tty

  my $mv = Crypt::Sodium::XS::MemVault->new_from_tty($path, $prompt, $flags);

C<$path> is optional. It is a filesystem path naming a TTY device. If not
provided, the default is the controlling tty for the process.

C<$prompt> is optional. It will be printed to the tty before reading input. If
not provided, the default is C<Password: >.

C<$flags> is optional. It is the L<flags|Crypt::Sodium::XS::ProtMem/FLAGS> of
the newly-created MemVault object. If not provided, the default is
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>.

Returns a L<Crypt::Sodium::XS::MemVault>: one line of input read from the TTY
device at C<$path>. The end-of-line character is not be included.

Echo will be disabled during input, making this appropriate for password input.

Croaks on failure.

=head1 FUNCTIONS

Nothing is exported by default. A C<:constructors> tag imports the
L</CONSTRUCTOR FUNCTIONS>. A C<:all> tag imports everything.

=head2 CONSTRUCTOR FUNCTIONS

=head2 mv_new

Shortcut to L</new>.

=head2 mv_from_base64

Shortcut to L</new_from_base64>.

=head2 mv_from_hex

Shortcut to L</new_from_hex>.

=head2 mv_from_fd

Shortcut to L</new_from_fd>.

=head2 mv_from_file

Shortcut to L</new_from_file>.

=head2 mv_from_tty

Shortcut to L</new_from_tty>.

=head2 mv_from_ttyno

Shortcut to L</new_from_ttyno>.

=head1 METHODS

=head2 bitwise_and

=head2 bitwise_and_equals

=head2 bitwise_or

=head2 bitwise_or_equals

=head2 bitwise_xor

=head2 bitwise_xor_equals

  $mv2 = $mv->bitwise_and($bytes);
  $mv2 = $mv->bitwise_or($other_mv);

  $mv->bitwise_xor_equals($bytes);
  $mv->bitwise_and_equals($other_mv);

Modifies protected memory using the associated bitwise operation with the
provided argument. The argument must be the same size, in bytes, as the
protected memory.

The C<*_equals> functions modify in-place. Other functions return a new
L<Crypt::Sodium::XS::MemVault>.

=head2 clone

  my $new_mv = $mv->clone;

Returns a new object C<$new_mv> with identical flags and contents to the
original C<$mv>.

=head2 compare

B<!!WARNING!!>: The results of this comparison method can be used to leak
information about the protected memory. If one can make arbitrary comparisons
and has any visibility to the result, the protected data can be determined in
(nbits - trailing_zero_bits) iterations! For a 256-bit key, that means it takes
no more than 256 tries to extract the key. This method is fixed-time, but the
only safe use of the result is whether it equals 0 or not, and L</memcmp> is a
better way to determine equality.

  $mv->compare($bytes, $size);
  $mv->compare($other_mv, $size);

Returns C<0> if the bytes are equal, C<-1> if C<$mv> is less than C<$other_mv>
(or C<$bytes>), or C<1> if C<$mv> is greater. This method runs in fixed-time
(for a given size), and compares bytes as little-endian arbitrary-length
integers. Comparible to the C<cmp> perl operator.

C<$size> is optional iif C<$mv> and C<$other_mv> (or C<$bytes>) are equal
sizes. If provided, only C<$size> bytes are compared. B<Note>: Croaks if a
comparison is of unequal sizes and C<$size> was not provided, or if C<$size> is
larger than either of the operands.

Croaks if C<$mv> or C<$other_mv> is conceptually "locked". See L</lock> and
L</unlock>.

B<Note>: This method is similar to L<memcmp(3)>; that is, it returns -1, 0, or
1 for the comparison results. For simple true/false equality comparisons, see
L</memcmp>. The naming is chosen here to be consistent with libsodium.

=head2 concat

  my $new_mv = $mv->concat($bytes);
  my $new_mv = $mv->concat($other_mv);

Returns a new L<Crypt::Sodium::Memvault> with the concatenated contents of
C<$mv> followed by C<$bytes> or the contents of C<$other_mv>. The new object's
flags will be the combined restrictions of C<$mv> and C<$new_mv>.

=head2 concat_inplace

  $mv->concat_inplace($appended_bytes);
  $mv->concat_inplace($another_mv);

Appends C<$appended_bytes> or the contents of C<$another_mv> to the end of
<$mv>. Returns C<$mv>.

=head2 flags

  my $flags = $mv->flags;
  $mv->flags($new_flags);

Return or set memory protection flags. See L<Crypt::Sodium::XS::ProtMem>.

=head2 from_base64

Shortcut for L<Crypt::Sodium::XS::MemVault/new_from_base64>.

=head2 from_hex

Shortcut for L<Crypt::Sodium::XS::MemVault/new_from_hex>.

=head2 index

B<!!WARNING!!>: This method does not run in constant-time and may leak
information about the protected memory.

  my $pos = $mv->index($substr, $offset);

Searches for an occurence of C<$substr> in protected memory. This is similar to
perl's own index function. Returns the first match of C<$substr> at or after
C<$offset>, or -1 if C<$substr> is not found.

C<$offset> is optional. If not provided, the search will begin at the start of
the protected memory. Unlike perl's index function, C<$offset> may not be
negative, and the method will croak if offset is beyond the last byte of
protected memory.

This method should only be used when protected memory starts with non-sensitive
data, and is guaranteed to find C<$substr> before any sensitive data.

Croaks if C<$mv> is conceptually "locked". See L</lock> and L</unlock>.

The C<Crypt::Sodium::XS::MemVault> object must be unlocked (L</unlock>) before
using this method.

=head2 is_locked

  my $is_locked = $mv->is_locked;

Returns a boolean indicating if the object is conceptually "locked."

=head2 is_zero

  my $is_null = $mv->is_zero;

Returns a boolean indicating if the protected memory consists of all null
bytes. Runs in constant time for a given size.

=head2 size

=head2 length (deprecated)

  my $size = $mv->size;
  my $size = $mv->length;

Returns the size, in bytes, of the protected memory. Runtime does not depend on
data.

=head2 lock

  $mv->lock;

Conceptually "lock" the object. This prevents use of the protected memory from
perl in a way which could leak the data (i.e., stringification, L</index>, and
L</compare>).

=head2 memcmp

  $mv->memcmp($bytes, $size);
  $mv->memcmp($other_mv, $size);

Returns true if the bytes are exactly equal, false otherwise. This method runs
in fixed-time (for a given size), and compares bytes as little-endian
arbitrary-length integers.

C<$size> is optional iif C<$mv> and C<$other_mv> (or C<$bytes>) are equal
sizes. If provided, only C<$size> bytes are compared. B<Note>: Croaks if
operands are unequal sizes and C<$size> was not provided, or if C<$size> is
larger than either of the operands.

When a comparison involves secret data (e.g. a key, a password, etc.), it is
critical to use a constant-time comparison function. This property does not
relate to computational complexity: it means the time needed to perform the
comparison is the same for all data of the same size. The goal is to mitigate
side-channel attacks.

B<Note>: L</memcmp> in libsodium is different than L<memcmp(3)>. This method
returns only true/false for equality, not -1, 0, or 1 for the comparison
results. For that, see L</compare>. The naming is chosen here to be consistent
with libsodium.

=head2 pad

=head2 unpad

  my $padded_mv = $mv->pad(32);
  my $unpadded_mv = $padded->unpad(32);

Returns a new L<Crypt::Sodium::XS::MemVault> with the contents of C<$mv> padded
or unpadded respectively, to the next multiple of C<$blocksize> bytes.

These functions use the ISO/IEC 7816-4 padding algorithm. It supports arbitrary
block sizes, ensures that the padding data are checked for computing the
unpadded length, and is more resistant to some classes of attacks than other
standard padding algorithms.

Notes:

=over 4

Padding should be applied before encryption and removed after decryption.

Usage of padding to hide the length of a password is not recommended. A client
willing to send a password to a server should hash it instead, even with a
single iteration of the hash function.

This ensures that the length of the transmitted data is constant and that the
server doesn’t effortlessly get a copy of the password.

Applications may eventually leak the unpadded length via side channels, but the
sodium_pad() and sodium_unpad() functions themselves try to minimize side
channels for a given length & <block size mask> value.

=back

=head2 to_file

  $mv->to_file($path, $mode);

C<$path> is a filesystem path. It will be created if it does not exist.

C<$mode> is optional. It is the mode of C<$path> if the file is created. If not
provided, the default is C<0600>. The mode will be modified by the current
umask.

Returns number of bytes written. Croaks on failure.

=head2 to_base64

  my $new_mv = $mv->to_base64($variant);

Returns a new L<Crypt::Sodium::XS::MemVault> with the contents encoded in
base64.

C<$variant> is optional (default:
L<Crypt::Sodium::XS::Base64/BASE64_VARIANT_URLSAFE_NO_PADDING>). See
L<Crypt::Sodium::XS::Base64/CONSTANTS>.

=head2 to_bytes

B<!!WARNING!!>: This method returns protected memory as a normal perl byte
string. This should not normally be necessary.

  my $bytes = $mv->to_bytes;

Returns the protected memory as a byte string. This is the method used to
overload stringification. Consider carefully before using.

Croaks if C<$mv> is conceptually "locked". See L</lock> and L</unlock>.

=head2 to_hex

  my $new_mv = $mv->to_hex;

Returns a new L<Crypt::Sodium::XS::MemVault> with the contents encoded as a
hexadecimal string.

=head2 unlock

  $mv->unlock;

Conceptually "unlock" the object. This allows access to the protected memory
from perl (i.e., stringification, L</index>, and L</compare>).

=head2 memzero

  $mv->memzero;

Overwrites protected memory with null bytes.

You may not need to call this yourself; unless using both of the non-default
flags L<Crypt::Sodium::XS::ProtMem/PROTMEM_FLAGS_MALLOC_PLAIN> and
L<Crypt::Sodium::XS::ProtMem/PROTMEM_FLAGS_MEMZERO_DISABLED> (or
L<Crypt::Sodium::XS::ProtMem/PROTMEM_ALL_DISABLED>), the memory is zeroed when
the object is destroyed.

=head1 OVERLOADS

=head2 boolean

  my $is_empty = !$mv;
  my $is_not_empty = !!$mv;

=head2 Equality eq, ==, ne, !=

  my $is_equal = $mv eq $bytes;
  my $is_equal = $bytes eq $mv;
  my $is_equal = $mv eq $other_mv;
  my $not_equal = $mv ne $bytes;
  my $not_equal = $bytes ne $mv;
  my $not_equal = $mv ne $other_mv;

Compares operands as arbitrary-length little-endian integers. Comparisons are
made in fixed-time (for a given size). See L</memcmp>.

=head2 Comparisons lt, E<lt>, le, E<lt>=, gt, E<gt>, ge, E<gt>=

  my $less = $mv < $bytes;
  my $less = $mv lt $bytes;
  my $less = $bytes < $mv;
  my $less = $bytes lt $mv;
  my $less = $mv < $other_mv;
  my $less = $mv lt $other_mv;
  ...

All comparisons treat their operands as arbitrary-length little-endian
integers. Comparisons are made in fixed-type (for a given size), but the
results can leak information about protected memory. See L</compare>.

Croaks if C<$mv> or C<$other_mv> is conceptually "locked". See L</lock> and
L</unlock>.

=head2 stringification

  my $var = "$mv";

Equivalent to L</to_bytes>. Stringification will croak if the
L<Crypt::Sodium::XS::MemVault> is conceptually "locked". See L</lock> and
L</unlock>. See also L</to_bytes>.

=head2 concatenation

  my $new_mv = $mv . $string;
  my $new_mv = $string . $mv;
  my $new_mv = $mv . $other_mv;

Note: C<.=> is equivalent to L</concat_inplace>.

=head2 repetition

  my $new_mv = $mv x 3;

=head2 bitwise and

  my $new_mv = $mv & $bytes;
  my $new_mv = $bytes & $mv;
  my $new_mv = $mv & $other_mv;
  $mv &= $other_mv;

C<&> is equivalent to L</bitwise_and>.

C<&=> is equivalent to L</bitwise_and_equals>.

=head2 bitwise or

  my $new_mv = $mv | $bytes;
  my $new_mv = $bytes | $mv;
  my $new_mv = $mv | $other_mv;
  $new_mv |= $other_mv;

C<|> is equivalent to L</bitwise_or>.

C<|=> is equivalent to L</bitwise_or_equals>.

=head2 bitwise exclusive-or

  my $new_mv = $mv ^ $bytes;
  my $new_mv = $bytes ^ $mv;
  my $new_mv = $mv ^ $other_mv;

C<^> is equivalent to L</bitwise_xor>.

C<^=> is equivalent to L</bitwise_xor_equals>.

=head1 FEEDBACK

For reporting bugs, giving feedback, submitting patches, etc. please use the
following:

=over 4

=item *

RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Crypt-Sodium-XS>

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

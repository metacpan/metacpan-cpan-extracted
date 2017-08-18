=head1 NAME

Convert::Scalar - convert between different representations of perl scalars

=head1 SYNOPSIS

 use Convert::Scalar;

=head1 DESCRIPTION

This module exports various internal perl methods that change the internal
representation or state of a perl scalar. All of these work in-place, that
is, they modify their scalar argument. No functions are exported by default.

The following export tags exist:

 :utf8   all functions with utf8 in their name
 :taint  all functions with taint in their name
 :refcnt all functions with refcnt in their name
 :ok     all *ok-functions.

=over 4

=cut

package Convert::Scalar;

BEGIN {
   $VERSION = 1.12;
   @ISA = qw(Exporter);
   @EXPORT_OK = qw(readonly readonly_on readonly_off weaken unmagic len grow extend extend_read readall writeall);
   %EXPORT_TAGS = (
      taint  => [qw(taint untaint tainted)],
      utf8   => [qw(utf8 utf8_on utf8_off utf8_valid utf8_upgrade utf8_downgrade utf8_encode utf8_decode utf8_length)],
      refcnt => [qw(refcnt refcnt_inc refcnt_dec refcnt_rv refcnt_inc_rv refcnt_dec_rv)],
      ok     => [qw(ok uok rok pok nok niok)],
   );

   require Exporter;
   Exporter::export_ok_tags(keys %EXPORT_TAGS);

   require XSLoader;
   XSLoader::load Convert::Scalar, $VERSION;
}

=item utf8 scalar[, mode]

Returns true when the given scalar is marked as utf8, false otherwise. If
the optional mode argument is given, also forces the interpretation of the
string to utf8 (mode true) or plain bytes (mode false). The actual (byte-)
content is not changed. The return value always reflects the state before
any modification is done.

This function is useful when you "import" utf8-data into perl, or when
some external function (e.g. storing/retrieving from a database) removes
the utf8-flag.

=item utf8_on scalar

Similar to C<utf8 scalar, 1>, but additionally returns the scalar (the
argument is still modified in-place).

=item utf8_off scalar

Similar to C<utf8 scalar, 0>, but additionally returns the scalar (the
argument is still modified in-place).

=item utf8_valid scalar [Perl 5.7]

Returns true if the bytes inside the scalar form a valid utf8 string,
false otherwise (the check is independent of the actual encoding perl
thinks the string is in).

=item utf8_upgrade scalar

Convert the string content of the scalar in-place to its UTF8-encoded form
(and also returns it).

=item utf8_downgrade scalar[, fail_ok=0]

Attempt to convert the string content of the scalar from UTF8-encoded to
ISO-8859-1. This may not be possible if the string contains characters
that cannot be represented in a single byte; if this is the case, it
leaves the scalar unchanged and either returns false or, if C<fail_ok> is
not true (the default), croaks.

=item utf8_encode scalar

Convert the string value of the scalar to UTF8-encoded, but then turn off
the C<SvUTF8> flag so that it looks like bytes to perl again. (Might be
removed in future versions).

=item utf8_length scalar

Returns the number of characters in the string, counting wide UTF8
characters as a single character, independent of wether the scalar is
marked as containing bytes or mulitbyte characters.

=item $old = readonly scalar[, $new]

Returns whether the scalar is currently readonly, and sets or clears the
readonly status if a new status is given.

=item readonly_on scalar

Sets the readonly flag on the scalar.

=item readonly_off scalar

Clears the readonly flag on the scalar.

=item unmagic scalar, type

Remove the specified magic from the scalar (DANGEROUS!).

=item weaken scalar

Weaken a reference. (See also L<WeakRef>).

=item taint scalar

Taint the scalar.

=item tainted scalar

returns true when the scalar is tainted, false otherwise.

=item untaint scalar

Remove the tainted flag from the specified scalar.

=item length = len scalar

Returns SvLEN (scalar), that is, the actual number of bytes allocated to
the string value, or C<undef>, is the scalar has no string value.

=item scalar = grow scalar, newlen

Sets the memory area used for the scalar to the given length, if the
current length is less than the new value. This does not affect the
contents of the scalar, but is only useful to "pre-allocate" memory space
if you know the scalar will grow. The return value is the modified scalar
(the scalar is modified in-place).

=item scalar = extend scalar, addlen=64

Reserves enough space in the scalar so that addlen bytes can be appended
without reallocating it. The actual contents of the scalar will not be
affected. The modified scalar will also be returned.

This function is meant to make append workloads efficient - if you append
a short string to a scalar many times (millions of times), then perl will
have to reallocate and copy the scalar basically every time.

If you instead use C<extend $scalar, length $shortstring>, then
Convert::Scalar will use a "size to next power of two, roughly" algorithm,
so as the scalar grows, perl will have to resize and copy it less and less
often.

=item nread = extend_read fh, scalar, addlen=64

Calls C<extend scalar, addlen> to ensure some space is available, then
do the equivalent of C<sysread> to the end, to try to fill the extra
space. Returns how many bytes have been read, C<0> on EOF or undef> on
eror, just like C<sysread>.

This function is useful to implement many protocols where you read some
data, see if it is enough to decode, and if not, read some more, where the
naive or easy way of doing this would result in bad performance.

=item nread = read_all fh, scalar, length

Tries to read C<length> bytes into C<scalar>. Unlike C<read> or
C<sysread>, it will try to read more bytes if not all bytes could be read
in one go (this is often called C<xread> in C).

Returns the total nunmber of bytes read (normally C<length>, unless an
error or EOF occured), C<0> on EOF and C<undef> on errors.

=item nwritten = write_all fh, scalar

Like C<readall>, but for writes - the equivalent of the C<xwrite> function
often seen in C.

=item refcnt scalar[, newrefcnt]

Returns the current reference count of the given scalar and optionally sets it to
the given reference count.

=item refcnt_inc scalar

Increments the reference count of the given scalar inplace.

=item refcnt_dec scalar

Decrements the reference count of the given scalar inplace. Use C<weaken>
instead if you understand what this function is fore. Better yet: don't
use this module in this case.

=item refcnt_rv scalar[, newrefcnt]

Works like C<refcnt>, but dereferences the given reference first. This is
useful to find the reference count of arrays or hashes, which cannot be
passed directly. Remember that taking a reference of some object increases
it's reference count, so the reference count used by the C<*_rv>-functions
tend to be one higher.

=item refcnt_inc_rv scalar

Works like C<refcnt_inc>, but dereferences the given reference first.

=item refcnt_dec_rv scalar

Works like C<refcnt_dec>, but dereferences the given reference first.

=item ok scalar

=item uok scalar

=item rok scalar

=item pok scalar

=item nok scalar

=item niok scalar

Calls SvOK, SvUOK, SvROK, SvPOK, SvNOK or SvNIOK on the given scalar,
respectively.

=back

=head2 CANDIDATES FOR FUTURE RELEASES

The following API functions (L<perlapi>) are considered for future
inclusion in this module If you want them, write me.

 sv_upgrade
 sv_pvn_force
 sv_pvutf8n_force
 the sv2xx family

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1


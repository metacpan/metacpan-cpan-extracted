package Crypt::Sodium::XS::ProtMem;
use strict;
use warnings;

use Exporter 'import';
use Crypt::Sodium::XS;

_define_constants();

our %EXPORT_TAGS = (
  functions => [qw[
    protmem_flags_decrypt_default
    protmem_flags_key_default
    protmem_flags_memvault_default
    protmem_flags_state_default
  ]],
  constants => [qw[
    PROTMEM_ALL_DISABLED
    PROTMEM_ALL_ENABLED
    PROTMEM_FLAGS_LOCK_LOCKED
    PROTMEM_FLAGS_LOCK_UNLOCKED
    PROTMEM_FLAGS_MLOCK_STRICT
    PROTMEM_FLAGS_MLOCK_PERMISSIVE
    PROTMEM_FLAGS_MLOCK_NONE
    PROTMEM_FLAGS_MPROTECT_NOACCESS
    PROTMEM_FLAGS_MPROTECT_RO
    PROTMEM_FLAGS_MPROTECT_RW
    PROTMEM_FLAGS_MEMZERO_ENABLED
    PROTMEM_FLAGS_MEMZERO_DISABLED
    PROTMEM_FLAGS_MALLOC_SODIUM
    PROTMEM_FLAGS_MALLOC_PLAIN
    PROTMEM_MASK_LOCK
    PROTMEM_MASK_MLOCK
    PROTMEM_MASK_MPROTECT
    PROTMEM_MASK_MEMZERO
    PROTMEM_MASK_MALLOC
  ]],
);
$EXPORT_TAGS{all} = [@{$EXPORT_TAGS{functions}}, @{$EXPORT_TAGS{constants}}];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

Crypt::Sodium::XS::ProtMem - Memory protection functions and constants

=head1 SYNOPSIS

  use Crypt::Sodium::XS::ProtMem ":all";

  # read the docs first!
  # removing mlock requirement on keys
  my $flags = protmem_flags_key_default();
  $flags &= ~PROTMEM_MASK_MLOCK;
  $flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
  my $old_flags = protmem_flags_key_default($flags);

  my $flags = protmem_flags_state_default();
  if (($flags & PROTMEM_MASK_MALLOC) == PROTMEM_FLAGS_MALLOC_PLAIN) {
    # no libsodium malloc, mprotect, or mlock for hash states by default
  }

  # removing all protection on multipart states
  $old_flags = protmem_flags_state_default(PROTMEM_ALL_DISABLED);

=head1 DESCRIPTION

Throughout L<Crypt::Sodium::XS>, many functions and methods return sensitive or
potentially sensitive data. That data is protected by returning
L<Crypt::Sodium::XS::MemVault> or other opaque state objects in these cases.
Those functions and methods will take a C<$flags> argument, controlling what
memory protections are applied. There are also global default flags for the
different scenarios in which the objects appear. The L</FUNCTIONS> and
L</CONSTANTS> in this package are for creating and examining such C<$flags>, as
well as getting and setting the global defaults. There are separate global
defaults (documented below) for the following types of data:

In general, protected memory objects can be simply treated as black-box
objects. L<Crypt::Sodium::XS> will handle access internally as necessary on its
own. For example, after calling a keygen function or loading a MemVault from a
key file, the result can be passed as the key to an encrypt function. The perl
programmer does not need to explicitly take any extra steps to use things this
way (no unlocking/locking needed).

=over 4

=item secret keys

=item decrypted data

=item multipart states

=item explicitly-created memvaults

=back

The flags control the following types of memory protection:

=over 4

=item mprotect

=item mlock

=item malloc

=item memzero

=item Conceptual "locking" of the object

Only for L<Crypt::Sodium::XS::MemVault> objects.

=back

See L</MEMORY SAFETY> for more gory details.

=head1 FLAGS

WARNING: Setting flags can be tricky. Be careful. It is intended to release a
simpler interface in the future, wrapping the complexity exposed here.

The value of flags must always be a bitwise-ORed combination of flag constants.
Constants for masks can be used to get or set the values of different
"categories" of protection. The value found with the appropriate mask is always
equal to one of the flag constants in that "category". It must only be set to
exactly one of the flag constants from its category. See the first example in
L</SYNOPSIS>. To modify flags from a "category", mask it off then bitwise-OR a
single constant from that "category".

Flags must be compared by applying the appropriate mask and then comparing by
equality to constants. See the second example in L</SYNOPSIS>.

Note: All bit flags, when set true, indicate disabling a protection or
restriction. Thus, the most restrictive flag set is always 0. This is so that
if a "category" of flags is skipped in a full flag set, it will be left at the
default all-protections state. It is still recommended to be explicit when
creating flags and use all categories.

=head1 RECOMMENDATIONS

All defaults in this distribution are restrictive-by-default. Put another way,
protection-enabled-by-default. It is up to the developer to decide where it may
be appropriate for their use to lessen protections. It is up to the user (via
environment variables) to decide if they wish to lessen (or increase)
protections for their environment. Application developers are encouraged to
leave the defaults.

Even if just playing, you are encouraged to leave the defaults. It may help
prevent surprises when protections are enabled.

The most reasonable places one might want to lessen default protections are
hash states and decrypted data.

The default flags for hash states are restrictive because the internal state
could be sensitive depending on use of the output. If no multipart hashing is
used in a way that internal state is sensitive, it is reasonable to set default
state flags to L</PROTMEM_ALL_DISABLED>.

The default flags for decrypted data are also restrictive. If decrypted data
will always be accessed from perl (in any way), then it may be reasonable
for your environment to also use L</PROTMEM_ALL_DISABLED> for decrypted data.
It might also be reasonable to use just L</PROTMEM_FLAGS_MLOCK_NONE> for
decrypted data if very large messages will be decrypted (at once rather than
chunked) to preserve limited locked memory. See the information below about
mlock.

=head2 CATEGORY-SPECIFIC RECOMMENDATIONS

mprotect protections should only be lessened when the perl interpreter and any
loaded libraries are fully trusted, including any threads (interpreter or
system) in use. It should probably not be disabled when perl is embedded in
another application; it offers increased security from bugs or vulnerabilities
in the application or its libraries. Consider carefully.

mlock protections should only be lessened when data isn't sensitive or on a
system with encrypted or no swap. If "Failed to allocate protmem" errors are
being generated because of limits on locked memory, it is a better idea to
increase the allowed locked memory (ulimit, prlimit) rather than removing the
protection. If that is not possible, follow the earlier advice before
disabling: no sensitive data, or no swap, or encrypted swap.

malloc protections should only be lessened if you're ok with using your
system's regular malloc, *as well as* disabling mprotect and mlock. It is
expected in the future to allow mprotect and mlock without libsodium's malloc.

memzero protection should really be left in place for any sensitive data.

Conceptual "locking" can be disabled if you expect to always extract the data
into perl anyway. It should otherwise be left in place to prevent accidental
exposure of data; specifically to avoid stringification and other overloads
from C<Crypt::Sodium::XS::MemVault> that could be triggered by debugging,
profiling, logging, etc.

=head1 ENVIRONMENT VARIABLES

Environment variables are available to control the global defaults for each
"category" of memory protections.

You should always get the values from the constants available in this package.
For example, to print the default all-enabled flags value (0):

  perl -MCrypt::Sodium::XS::ProtMem=:constants <<'EOPERL'
    print PROTMEM_FLAGS_LOCK_LOCKED
          | PROTMEM_FLAGS_MLOCK_STRICT
          | PROTMEM_FLAGS_MPROTECT_NOACCESS
          | PROTMEM_FLAGS_MEMZERO_ENABLED
          | PROTMEM_FLAGS_MALLOC_SODIUM
    , "\n";
  EOPERL

For a value to disable everything:

  perl -MCrypt::Sodium::XS::ProtMem=:constants -E 'say PROTMEM_ALL_DISABLED'

=head2 PROTMEM_FLAGS_KEY

Setting this environment variable is identical to calling
L</protmem_flags_key_default> with the value of the variable.

=head2 PROTMEM_FLAGS_DECRYPT

Setting this environment variable is identical to calling
L</protmem_flags_decrypt_default> with the value of the variable.

=head2 PROTMEM_FLAGS_STATE

Setting this environment variable is identical to calling
L</protmem_flags_state_default> with the value of the variable.

=head2 PROTMEM_FLAGS_MEMVAULT

Setting this environment variable is identical to calling
L</protmem_flags_memvault_default> with the value of the variable.

=head2 PROTMEM_FLAGS_ALL

Setting this special environment variable will use the value of the variable to
set all flags "categories". Consider carefully before using.

=head1 FUNCTIONS

Nothing is exported by default. The tag C<:functions> imports all
L</FUNCTIONS>. The tag C<:all> imports everything.

=head2 protmem_flags_key_default

  my $flags = protmem_flags_key_default();
  protmem_flags_key_default($new_flags);

Get or set the default flags of L<Crypt::Sodium::XS::MemVault>s created to
store secret keys, as well as opaque object states that contain key material.

The default flags are L</PROTMEM_FLAGS_ALL_ENABLED>.

=head2 protmem_flags_decrypt_default

  my $flags = protmem_flags_decrypt_default();
  protmem_flags_decrypt_default($new_flags);

Get or set the default flags of L<Crypt::Sodium::XS::MemVault>s created to
store decrypted data.

The default flags are L</PROTMEM_FLAGS_ALL_ENABLED>.

=head2 protmem_flags_state_default

  my $flags = protmem_flags_state_default();
  protmem_flags_state_default($new_flags);

Get or set the default mprotect level of states created for multi-part
interfaces which do not contain key material. The internal state is protected
by the library based on this setting.

The default flags are L</PROTMEM_FLAGS_ALL_ENABLED>.

=head2 protmem_flags_memvault_default

  my $flags = protmem_flags_memvault_default();
  protmem_flags_memvault_default($new_flags);

Get or set the default flags of explicitly-created
L<Crypt::Sodium::XS::MemVault>s.

The default flags are L</PROTMEM_FLAGS_ALL_ENABLED>.

=head1 CONSTANTS

Nothing is exported by default. The tag C<:constants> imports all
L</CONSTANTS>. The tag C<:all> imports everything.

=head2 MEMORY PROTECTION (mprotect) FLAGS

=over 4

=item PROTMEM_MASK_MPROTECT

Bitwise mask of mprotect portion of flags. Bitwise and (C<&>) of this mask and
flags is equal to one of:

=over 4

=item PROTMEM_FLAGS_MPROTECT_NOACCESS

Protected memory is left inaccessible to the process, except during internal
library operation.

=item PROTMEM_FLAGS_MPROTECT_RO

Protected memory is left read-only to the process, except during internal
library operation.

=item PROTMEM_FLAGS_MPROTECT_WR

Write-only protection is not available, as it is not provided by libsodium.
This constant is provided for completeness only. Do not set mprotect flags to
this flag alone.

=item PROTMEM_FLAGS_MPROTECT_RW

Protected memory is left read-write (effectively disabling access protection).

=back

=back

=head2 MEMORY LOCKING (mlock) FLAGS

=over 4

=item PROTMEM_MASK_MLOCK

Bitwise mask of mlock portion of flags. Bitwise and (C<&>) of this mask and
flags are equal to one of:

=over 4

=item PROTMEM_FLAGS_MLOCK_STRICT

Protected memory locking (preventing memory from swapping to disk) is enforced.

=item PROTMEM_FLAGS_MLOCK_PERMISSIVE

Protected memory locking (preventing memory from swapping to disk) is allowed
to fail. This is libsodium's default behavior. Note that there is no flag to
entirely disable mlock of protected memory. This is a limitation of the
libsodium memory allocation interface.

=item PROTMEM_FLAGS_MLOCK_NONE

Although libsodium will always attempt to mlock memory when using its
allocator, by setting mlock flags to L</PROTMEM_MEMLOCK_NONE> the allocated
memory will be immediately munlocked. This can help preserve limited locked
memory resources.

=back

=back

=head2 MEMORY ALLOCATION (malloc) FLAGS

=over 4

=item PROTMEM_MASK_MALLOC

Bitwise mask of malloc portion of flags. Bitwise and (C<&>) of this mask and
flags are equal to one of:

=over 4

=item PROTMEM_FLAGS_MALLOC_SODIUM

Protected memory uses libsodium malloc and the associated protections it
provides.

=item PROTMEM_FLAGS_MALLOC_PLAIN

Protected memory uses plain C<malloc>, and the protections provided by
libsodium allocation are unavailable.

=back

=back

=head2 MEMORY CLEANUP FLAGS

B<NOTE>: these flags only take effect when using L</PROTMEM_FLAGS_MALLOC_PLAIN>.
With sodium malloc, memory is always zeroed when freed.

=over 4

=item PROTMEM_MASK_MEMZERO

Bitwise mask of memzero portion of flags. Bitwise and (C<&>) of this mask and
flags are equal to one of:

=over 4

=item PROTMEM_FLAGS_MEMZERO_ENABLED

Protected memory will be overwritten with null bytes when freed.

=item PROTMEM_FLAGS_MEMZERO_DISABLED

Protected memory will be left untouched when freed.

=back

=back

=head2 CONCEPTUAL LOCKING FLAGS

B<NOTE>: these flags apply only to L<Crypt::Sodium::XS::MemVault> objects.

=over 4

=item PROTMEM_MASK_LOCK

Bitwise mask of conceptual locking portion of flags. Bitwise and (C<&>) of this
mask and flags are equal to one of:

=over 4

=item PROTMEM_FLAGS_LOCK_LOCKED

MemVault will be locked by default, and must be unlocked to access the data.

=item PROTMEM_FLAGS_LOCK_UNLOCKED

MemVault will be unlocked by default, and may always be accessed.

=back

=back

=head2 ALL COMBINED

Two special flag sets have their own constants. They can be used directly as a
C<$flags> value without any masking necessary.

=over 4

=item PROTMEM_ALL_ENABLED

This constant is the set of flags (covers all "categories") necessary to
enable any current and future memory protections.

Equivalent to the combination (bitwise-OR) of the constants:

=over 4

=item L</PROTMEM_FLAGS_MALLOC_SODIUM>

=item L</PROTMEM_FLAGS_MEMZERO_ENABLED>

=item L</PROTMEM_FLAGS_MLOCK_STRICT>,

=item L</PROTMEM_FLAGS_MPROTECT_NOACCESS>

=item L</PROTMEM_FLAGS_LOCK_LOCKED>.

=back

=item PROTMEM_ALL_DISABLED

This constant is the set of flags (covers all "categories") necessary to
disable any current and future memory protections.

NOTE: When using </PROTMEM_ALL_DISABLED> with L<Crypt::Sodium::XS::MemVault>
objects, they should be treated as regular perl scalars and rely on overloading
(e.g., C<sodium_bin2base64($memvault)> rather than C<$memvault-E<gt>to_base64>.
Future optimization may indeed return regular perl scalars with
L</PROTMEM_ALL_DISABLED>.

=back

=head1 MEMORY SAFETY

Memory protections include:

=over 4

=item mprotect

By default, protected memory is set to PROT_NONE (no access allowed) and only
unprotected during internal library operation when necessary. This guards
against any potential memory leaking bugs in perl itself or other parts of the
process runtime.

This protection can be lowered by setting flags to L</PROTMEM_FLAGS_MPROTECT_RO>
(read-only) or L</PROTMEM_FLAGS_MPROTECT_RW> (read-write, no protection). It is
disabled entirely by L</PROTMEM_FLAGS_MALLOC_PLAIN>.

=item mlock

By default, protected memory is locked with C<sodium_mlock>, which means that
it will not be swapped to disk. On operating systems supporting MAP_NOCORE or
MADV_DONTDUMP, it will also not be part of core dumps. Most operating systems
place limits on how much locked memory any individual process is allowed. On
such systems, C<ulimit> or C<prlimit> utility is likely available to increase
those limits if necessary.

This protection is disabled by any of the L</PROTMEM_FLAGS_MLOCK_PERMISSIVE>,
L</PROTMEM_FLAGS_MLOCK_NONE>, or L</PROTMEM_FLAGS_MALLOC_PLAIN> flags. B<NOTE>: When
using sodium malloc, libsodium always attempts to mlock allocated memory but
ignores failure. With L</PROTMEM_FLAGS_MLOCK_PERMISSIVE>, an extra mlock (to
ensure memory locking) call is avoided. With L</PROTMEM_FLAGS_MLOCK_NONE>, an
extra call is made to ensure memory is not locked.

=item libsodium malloc

By default, L<Crypt::Sodium::XS> protected memory objects are allocated with
C<sodium_malloc>, which is placed at the end of a page boundary, immediately
followed by a guard page. As a result, accessing memory past the end of the
region will immediately terminate the application. A canary is also placed
right before the returned pointer. Modifications of this canary are detected
when the object is no longer referenced and is freed with C<sodium_free>. This
will also cause the application to immediately terminate when detected. An
additional guard page is placed before this canary to make it less likely for
sensitive data to be accessible when reading past the end of an unrelated
region. The allocated region is filled with 0xdb bytes in order to help catch
bugs due to uninitialized data.

This protection is disabled by the L</PROTMEM_FLAGS_MALLOC_PLAIN> flag. B<NOTE>:
disabling this protection also disables mprotect and mlock protections.

=item memory erasure

By default, when protected memory is freed it is overwritten by
C<sodium_memzero> so that no sensitive data is left behind.

This protection is disabled using *BOTH* the L</PROTMEM_FLAGS_MALLOC_PLAIN> and
L</PROTMEM_FLAGS_MEMZERO_DISABLED> flags. It cannot be disabled when using libsodium
malloc.

=back

There are performance gains in disabling the provided safety nets. It is still
strongly recommended to leave all the default protections in place. The feature
most likely to impact performance is the zeroing of memory when freed. Please
consider carefully before disabling!

=head2 MemVault

Sensitive data (secret keys and decrypted data) generated by
L<Crypt::Sodium::XS> is stored in a L<Crypt::Sodium::MemVault> object.

By default, all L<Crypt::Sodium::XS::MemVault> objects are in a "locked" state.
From perl code, this prevents direct access to the protected data; in order to
access it, it must first be "unlocked" with the C<unlock> method. It can be
re-locked after use with the C<lock> method. In general, a "locked" MemVault
will not allow data to be copied to perl-managed memory. Some methods (e.g.,
size, comparison, index) still provide potentially sensitive information about
contents of a "locked" MemVault. Great care should be taken directly using any
MemVault methods.

See L<Crypt::Sodium::XS::MemVault> for more.

=head2 multi-part states

All multi-part functionality for hashing, encryption, and decryption uses
protected memory objects as well, with the features listed above. Unlike
L<Crypt::Sodium::XS::MemVault>, there is no conceptual "locking" for these
objects, as the state data is not directly accessible to perl code.

=head1 BUGS/KNOWN LIMITATIONS

The mprotect restrictions should not be relied upon in a threaded (interpreter
or system threads) context, as it is largely process-global. This is a
limitation of the mprotect interface.

In general, L<Crypt::Sodium::XS> is not intendend for a multi-threaded
environment.

=head1 SEE ALSO

=over 4

=item * L<Crypt::Sodium::XS::MemVault>

Protected memory objects

=item * L<libsodium|https://doc.libsodium.org/memory_management>

=back

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

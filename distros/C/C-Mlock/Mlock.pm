package C::Mlock;

use strict;
use vars qw($VERSION @ISA);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
$VERSION = "1.11";

bootstrap C::Mlock $VERSION;


1

__END__

=head1 NAME

C::Mlock - A locked in RAM memory region

=head1 SYNOPSIS

    use C::Mlock;

    $a = new C::Mlock [$nPages];

    print $a->pagesize;

    $bytesAllocated = $a->initialize();

    $bytesAllocated = $a->set_pages($nPages);
    $bytesAllocated = $a->set_size($nBytes);

    print "memory region locked" if $a->is_locked();
    print "process locked in memory" if $a->process_locked();

    $a->store($data, $length);
    print $a->get();

    $a->lockall();
    $a->unlockall();

    $a->dump();

=head1 DESCRIPTION

C<C::Mlock> implements a set of calls to mlock(), munlock()
mlockall() and munlockall().;
On new() It allocates memory pages specified and will lock them,
into RAM (preventing them from going to swap memory.).

This module was written for secure(ish) storage  purposes
like you would use in cryptographic routines particularly those
manipulating private keys.

lockall/unlockall is available to lock the entire process
instead of just a memory region however it could easily fail due
to system constraints so locking the region in the constructor
is always enabled.  unlockall will unlock the process and
immediately relock the memory reserved in the constructor.

=head1 METHODS

=over 4

=item I<$a> = I<new> I<C::Mlock> I<[$nPages]>

Creates and returns a new C<C::Mlock> object.
The optional $nPages specifies the number of pages to be
allocated and locked on return.

=item I<$a>->I<initialize>()

Will allocate the storage and lock it in memory if I<$nPages>
was not specified as part of the contructor.  Returns the
number of bytes available.

=item I<$a>->I<process_locked>()

Will return 1 if the process has been locked in RAM by a
successful mlockall() call.

=item I<$a>->I<is_locked>()

Will return 1 if the allocated memory cannot be paged to swap
(ie is locked in RAM)

=item I<$a>->I<pagesize>()

Will return the page size on this system.

=item I<$a>->I<set_size>(I<$bytes>)

Will set thelocked storage region to be of size I<$bytes>.

If this is called after bytes are written, it will reallocate
the storage to the new size and copy over all the data from
the old memory region before clearing and releasing it.

If the new size is smaller than the data stored, the data 
will be truncated to the new length.

=item I<$a>->I<set_pages>(I<$pages>)

Similar to C<set_size> it will set the allocation to bytes
that are a multiple of I<$pages>.

=item I<$a>->I<store>(I<$data>, I<$length>)

Stores the data in the allocated storage of length.  $data
can be of any type, however it will be truncated at $length
if the length is longer.  If the storage is insufficient
0 (zero) will be returned, otherwise 1 (one) is returned.

=item I<$a>->I<get>()

Returns the data as a scalar string.

=item I<$a>->I<lockall>()

Will lock the entire process in RAM, on error will croak.

=item I<$a>->I<unlockall>()

Will unlock the process from RAM (if locked) and immediately
relock the preallocted memory.

=item I<$a>->I<dump>()

Will return a hexdump of the memory allocated.

=back

=head1 WARNINGS

Users on systems may have restrictions on the amount of memory
that may be locked.  This may cause lockall() to fail with 
C<ENOMEM> which is not caught and will cause a fatal error.
Similarly if you attempt to C<set_size> or C<set_pages> and the
combined total of the original and new regions exceed the limit
on the user a fatal error will occur.

unlockall() knows nothing of other mlock() calls except those in
its own constructor, so if you have multiple instances and you
call unlockall() it will unlock the regions in those instances
and they will not be relocked.  It is recommended that you either
rely on lockall()/unlockall() or the internal locked storage but
not both.

When using this module for cryptography you should undef everything
in the same function if possible and overwrite each scalar
immediately to prevent the memory being put back into the pool
unwiped and therefore defeating the whole purpose of locking
the sensitive data in memory.

=head1 BUGS

Various failures in the C libraries are not checked.  Particularly
C<ENOMEM> where there isn't enough system memory to allow the
process or pages to be locked to RAM.  This is particularly noted
on systems such as linux and freebsd which restrict users (non root)
to disallowing the calls either totally or based on the memory
required to complete the lock (Thanks to Slaven Rezic for noting
that a user can only lock 64kB by defaul on debian/jessie machines
by default.)

=head1 AUTHOR

Michelle Sullivan, cpan@sorbs.net

=head1 SEE ALSO

perl(1), mlock(2), munlock(2), munlockall(2), mlockall(2)

=cut


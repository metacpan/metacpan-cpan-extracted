package DBM::Deep::Blue;

use 5.012;
use strict;
use warnings FATAL=>'all';

our $VERSION = '1.01';

require XSLoader;
XSLoader::load('DBM::Deep::Blue', $VERSION);


#----------------------------------------------------------------------
# DBM::Deep::Blue
# Philip R Brenan, 2010
#----------------------------------------------------------------------

=pod

=head1 Name

L<DBM::Deep::Blue|http::www.handybackup.org/DBM_Deep_Blue.html> - Memory
Mapped Paged Permanent Perl Objects with optional commit and rollback.

Windows only.

=head1 Synopsis

  use DBM::Deep::Blue;
  use Test::More;

   {my $m = DBM::Deep::Blue::file('memory.data');
    my $h = $m->allocGlobalHash;                   
       $h->{a}[1]{b}[2]{c}[3] =  'a1b2c2';
   }

  # A later execution ...

   {my $m = DBM::Deep::Blue::file('memory.data');
    my $h = $m->allocGlobalHash;                   
    is $h->{a}[1]{b}[2]{c}[3],   'a1b2c2';
   }

  done_testing;

=head1 Description

L<DBM::Deep::Blue|http::www.handybackup.org/DBM_Deep_Blue_html> makes
Perl Objects permanent, but pageable, using the standard Perl syntax for
manipulating nested data structures comprised of strings, hashes and arrays.

Permanent hashes and arrays may be blessed and auto vivified,
dereferenced and dumped: consequently you can use L<Data::Dump> or
L<Data::Dumper> and Perl debugger commands to examine data structures
built with
L<DBM::Deep::Blue|http::www.handybackup.org/DBM_Deep_Blue_html> in the
normal way.

Units of work can either be committed continuously or discretely using
L</begin_work()>, L</commit()>, L</rollback()>. Uncommitted changes are
rolled back automatically when a backing file is reopened. Blessing is
subject to rollback.

The data structures are held in a memory area backed by a file using
your computer's virtual paging mechanism created by L</file()>. On large
data structures, this allows
L<DBM::Deep::Blue|http::www.handybackup.org/DBM_Deep_Blue_html> to load
pages on demand as needed to locate data, and to write back to the
backing file only the pages containing modified data. By contrast, other
schemes for making Perl objects permanent have either to write the
entire data structure or track the changes made internally and then
write them piecemeal.

To obtain addressability to permanent data objects, you can call
L</allocGlobalHash()> or L</allocGlobalArray()> to create an array or
hash that can be immediately addressed. Other data can then be connected
to these structures.

Free space liberated by assigning new values to array and hash elements,
deleting hash keys, clearing arrays and hashes, and reducing the size of
arrays is automatically recycled. The memory area grows as needed and
within the confines of the available user virtual storage available in
one address space on your computer. A reference counting scheme is used
to detect objects that are not referenced by any other data structure
and should therefore be reclaimed. Thus a data object returned by
L<perlfunc/delete> from a hash should be assigned to some other data
structure before any other operation is performed on the memory area.
Space reclamation is suspended during a unit of work, any space
liberated is removed by L<commit()> or L<rollback()>. 
 

Memory structures can also be created without a backing file by using
the new() function.

L<DBM::Deep::Blue|http::www.handybackup.org/DBM_Deep_Blue_html> is
written in C.


=head1 Methods

=head2 Allocation

Use these methods to create a new memory area.

=over 2

=item new()

  my $m = DBM::Deep::Blue::new();

Creates a new memory structure

=item file()

  my $m = DBM::Deep::Blue::file("aaa.data");

Creates or reloads a memory structure in or from backing file
F<aaa.data>. If the file does not exist, it will be created. If it does
exist, processing continues with the the memory structure as saved in
the file.

Any uncommitted changes from an incomplete unit of work will be rolled
back when an existing file is reopened.

Please create any directory names in the file path before calling this
function.

=item allocGlobalHash()

  my $h = $m->allocGlobalHash();

If the backing file is being created, this will create a hash in the new
file. If the backing file is being reopened, $h will refer to the
existing global hash. Sub arrays and hashes can then be auto vivified
from this hash:

  $h->{a}[1]{b}[2] = "ccc";


=item allocGlobalArray()

  my $a = $m->allocGlobalArray();

If the backing file is being created, this will create an array in the
new file. If the backing file is being reopened, $a will refer to the
existing global array. Sub arrays and hashes can then be auto vivified
from this array:

  $a->[1]{a}[2]{b} = "ccc";

=back


=head2 Units Of Work

Use these methods to start and end units of work. A unit of work is a
sequence of operations that must either complete or whose effect must be
completely removed from the memory area.

=over 2

=item begin_work()

  $m->begin_work();

Starts a unit of work.

Normally, changes are committed continuously. Calling begin_work() starts
logging changes so that they can be rolled back with L</rollback()> or
committed with L</commit()>. Uncommitted changes are automatically rolled
back if the backing file is reopened with L</file()>.

Units of work are not nested. Calling L</begin_work()> more than once
before a matching L</commit()> or L</rollback()> has no effect.

=item commit()

  $m->commit();

Commit changes made in the current unit of work and return to continuous
commit mode.

=item rollback()

  $m->rollback();

Rollback changes made in the current unit of work and return to
continuous commit mode.

=back


=head2 Debugging

=over 2

=item dump()

  $m->dump("dump.data");

Dump the memory area to file: F<dump.data>.

=item size()

  my $s = 2 **($m->size());

$s will contain the size in bytes of the memory area.

=item dahs()

  $m->dahs();

Dump the sizes of internal arrays and hashes to stderr.

=back


=head1 Limitations

Windows only.

The L<perlfunc/delete> function for arrays has not been implemented as
its use is deprecated.

The L<perlfunc/splice> function has not been implemented.

Code, file handles and typeglobs are not supported. 


=head1 Exports

None.


=head1 Installation

The usual installation sequence modified slightly by being on Windows.

  perl Makefile.PL
  dmake
  dmake test
  dmake install

If you do not have gcc and dmake, you can get them from
L<http::www.strawberryperl.org>


=head1 See Also

L<DBM::Deep>


=head1 Acknowledgements

L<DBM::Deep::Blue|http::www.handybackup.org/DBM_Deep_Blue_html> uses many
of the tests from by L<DBM::Deep>.


=head1 Bugs

Please report bugs etc. through CPAN. To include a dump of your memory
area with your bug report, call:

  my $m = DBM::Deep::Blue::File(...);

  ... actions which demonstrate the bug

  $m->dump("zzz.data");

and include file F<zzz.data> with your bug report.


=head1 Licence

Perl Artistic


=head1 Copyright

Philip R Brenan, 2010, www.handybackup.org

=cut

1;
__END__


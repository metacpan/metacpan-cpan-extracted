package Data::CompactReadonly;

use warnings;
use strict;

use Data::CompactReadonly::V0::Node;

# Yuck, semver. I give in, the stupid cult that doesn't understand
# what the *number* bit of *version number* means has won.
our $VERSION = '0.0.1';

=head1 NAME

Data::CompactReadonly

=head1 DESCRIPTION

A Compact Read Only Database that consumes very little memory. Once created a
database can not be practically updated except by re-writing the whole thing.
The aim is for random-access read performance to be on a par with L<DBM::Deep>
and for files to be much smaller.

=head1 METHODS

=head2 create

Takes two arguments, the name of file into which to write a database, and some
data. The data can be undef, a number, some text, or a reference to an array
or hash that in turn consists of undefs, numbers, text, references to arrays or
hashes, and so on ad infinitum.

This method may be very slow. It constructs a file by making lots
of little writes and seek()ing all over the place. It doesn't do anything
clever to figure out what pointer size to use, it just tries the shortest
first, and then if that's not enough tries again, and again, bigger each time.
See L<Data::CompactReadonly::Format> for more on pointer sizes. It may also eat B<lots> of
memory. It keeps a cache of everything it has seen while building your
database, so that it can re-use data by just pointing at it instead of writing
multiple copies of the same data into the file.

Note that it will carefully preserve things that look like numbers but have
extraneous leading or trailing zeroes. "007", for instance, is text, not a number,
the leading zeroes are important. And while 7.10 is a number, the extra zero has
meaning - it tells you that the value is accurate to three significant figures. If
it were stored as a number, it would be retrieved as merely 7.1, accurate to only
two significant figures. We are happy to spend a little extra storage in the
interested of correctly storing your data. If you then go on to just treat 7.10
as a number in perl, and so as equivalent to 7.1 that is of course up to you.

=head2 read

Takes a single compulsory argument, which is a filename or an already open file
handle, and some options.

If the first argument is a filehandle, the current file pointer should be at
the start of the database (not necessarily at the start of the file; the
database could be in a C<__DATA__> segment) and B<must> have been opened in
"just the bytes ma'am" mode.

It is a fatal error to pass in a filehandle which was not opened correctly or
the name of a file that can't be opened or which doesn't contain a valid
database.

The options are name/value pairs. Valid options are:

=over

=item tie

If true return tied objects instead of normal objects. This means that you will
be able to access data by de-referencing and pretending to access elements
directly. Under the bonnet this wraps around the objects as documented below,
so is just a layer of indirection. On modern hardware you probably won't notice
the concomittant slow down but may appreciate the convenience.

=back

Returns the "root node" of the database. If that root node is a number, some
piece of text, or Null, then it is decoded and the value returned. Otherwise an
object (possibly a tied object) representing an Array or a Dictionary is returned.

=head1 OBJECTS

If you asked for normal objects to be returned instead of tied objects, then
these are sub-classes of either C<Data::CompactReadonly::Array> or
C<Data::CompactReadonly::Dictionary>. Both implement the following three methods:

=head2 id

Returns a unique id for this object within the database. Note that circular data
structures are supported, and looking at the C<id> is the only way to detect them.

This is not accessible when using tied objects.

=head2 count

Returns the number of elements in the structure.

=head2 indices

Returns a list of all the available indices in the structure.

=head2 element

Takes a single argument, which must match one of the values that would be returned
by C<indices>, and returns the associated data.

If the data is a number, Null, or text, the value will be returned directly. If the
data is in turn another array or dictionary, an object will be returned.

=head2 exists

Takes a single argument and tell you whether an index exists for it. It will still
die if you ask it fomr something stupid such as a floating point array index or
a Null dictionary entry.

=head1 UNSUPPORTED PERL TYPES

Globs, Regexes, References (except to Arrays and Dictionaries)

=head1 BUGS/FEEDBACK

Please report bugs by at L<https://github.com/DrHyde/perl-modules-Data-CompactReadonly/issues>, including, if possible, a test case.

=head1 SEE ALSO

L<DBM::Deep> if you need updateable databases.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Data-CompactReadonly.git>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2020 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

sub create {
    my($class, $file, $data) = @_;

    my $version = 0;

    PTR_SIZE: foreach my $ptr_size (1 .. 8) {
        my $byte5 = chr(($version << 3) + $ptr_size - 1);
        open(my $fh, '>:unix', $file) || die("Can't write $file: $! \n");
        print $fh "CROD$byte5";
        my $already_seen = {};
        eval {
            "Data::CompactReadonly::V${version}::Node"->_create(
                fh           => $fh,
                ptr_size     => $ptr_size,
                data         => $data,
                already_seen => $already_seen
            );
        };
        if($@ && index($@, "Data::CompactReadonly::V${version}::Node"->_ptr_blown()) != -1) {
            next PTR_SIZE;
        } elsif($@) { die($@); }
        last PTR_SIZE;
    }
}

sub read {
    my($class, $file, %args) = @_;
    my $fh;
    if(ref($file)) {
        $fh = $file;
        my @layers = PerlIO::get_layers($fh);
        if(grep { $_ !~ /^(unix|perlio|scalar)$/ } @layers) {
            die(
                "$class: file handle has invalid encoding [".
                join(', ', @layers).
                "]\n"
            );
        }
    } else {
        open($fh, '<', $file) || die("$class couldn't open file $file: $!\n");
        binmode($fh);
    }
    
    my $original_file_pointer = tell($fh);

    read($fh, my $header, 5);
    (my $byte5) = ($header =~ /^CROD(.)/);
    die("$class: $file header invalid: doesn't match /CROD./\n") unless(defined($byte5));

    my $version  = (ord($byte5) & 0b11111000) >> 3;
    my $ptr_size = (ord($byte5) & 0b00000111) + 1;
    die("$class: $file header invalid: bad version\n") if($version == 0b11111);

    return "Data::CompactReadonly::V${version}::Node"->_init(
        ptr_size            => $ptr_size,
        fh                  => $fh,
        db_base             => $original_file_pointer,
        exists($args{'tie'}) ? ('tie' => 1 ) : ()
    );
}

1;

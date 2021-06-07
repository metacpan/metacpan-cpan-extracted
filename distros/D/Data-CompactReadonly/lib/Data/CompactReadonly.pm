package Data::CompactReadonly;

use warnings;
use strict;

use Data::CompactReadonly::V0::Node;

# Yuck, semver. I give in, the stupid cult that doesn't understand
# what the *number* bit of *version number* means has won.
our $VERSION = '0.0.6';

=head1 NAME

Data::CompactReadonly

=head1 DESCRIPTION

A Compact Read Only Database that consumes very little memory. Once created a
database can not be practically updated except by re-writing the whole thing.
The aim is for random-access read performance to be on a par with L<DBM::Deep>
and for files to be much smaller.

=head1 VERSION 'NUMBERS'

This module uses semantic versioning. That means that the version 'number' isn't
really a number but has three parts: C<major.minor.patch>.

The C<major> number will increase when the API changes incompatibly;

The C<minor> number will increase when backward-compatible additions are made to the API;

The C<patch> number will increase when bugs are fixed backward-compatibly.

=head1 FILE FORMAT VERSIONS

All versions so far support file format version 0 only.

See L<Data::CompactReadonly::V0::Format> for details of what that means.

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

It tries really hard to preserve data types. So for example, C<60000> is stored
and read back as an integer, but C<"60000"> is stored and read back as a string.
This means that you can correctly store and retrieve C<"007"> but that C<007>
will have the leading zeroes removed before Data::CompactReadonly ever sees it
and so will be treated as exactly equivalent to C<7>. The same applies to floating
point values too. C<"7.10"> is stored as a four byte string, but C<7.10> is stored
the same as C<7.1>, as an eight byte IEEE754 double precision float. Note that
perl parses values like C<7.0> as floating point, and thus so does this module.

Finally, while the file format permits numeric keys in hashes, this method
always coerces them to text. This is because if you allow numeric keys,
numbers that can't be represented in an C<int>, such as 1e100 or 3.14 will
be subject to floating point imprecision, and so it is unlikely that you
will ever be able to retrieve them as no exact match is possible.

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

=item fast_collections

If true Dictionary keys and values will be permanently cached in memory the
first time they are seen, instead of being fetched from the file when needed.
Yes, this means that objects will grow in memory, potentially very large.
Only use this if if it an acceptable pay-off for much faster access.

This is not yet implemented for Arrays.

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
        eval {
            "Data::CompactReadonly::V${version}::Node"->_create(
                filename => $file,
                fh       => $fh,
                ptr_size => $ptr_size,
                data     => $data,
                globals  => { next_free_ptr => tell($fh), already_seen  => {} }
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
        map {
            exists($args{$_}) ? ($_ => 1 ) : ()
        } qw(fast_collections tie)
    );
}

1;

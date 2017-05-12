package Data::MATFile;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/read_matfile mi2word mx2word/;
use warnings;
use strict;
use 5.008;
use Carp;
our $VERSION = '0.04';
use Gzip::Faster;

# Nasty flag for debuggers

our $VERBOSE;

# Matlab constants

# Top-level types

use constant {
    miINT8 => 1,
    miUINT8 => 2,
    miINT16 => 3,
    miUINT16 => 4,
    miINT32 => 5,
    miUINT32 => 6,
    miSINGLE => 7,
    miRESERVE1 => 8,
    miDOUBLE => 9,
    miRESERVE2 => 10,
    miRESERVE3 => 11,
    miINT64 => 12,
    miUINT64 => 13,
    miMATRIX => 14,
    miCOMPRESSED => 15,
    miUTF8 => 16,
    miUTF16 => 17,
    miUTF32 => 18,
};

my %names = reverse (
    miINT8 => 1,
    miUINT8 => 2,
    miINT16 => 3,
    miUINT16 => 4,
    miINT32 => 5,
    miUINT32 => 6,
    miSINGLE => 7,
    miRESERVE1 => 8,
    miDOUBLE => 9,
    miRESERVE2 => 10,
    miRESERVE3 => 11,
    miINT64 => 12,
    miUINT64 => 13,
    miMATRIX => 14,
    miCOMPRESSED => 15,
    miUTF8 => 16,
    miUTF16 => 17,
    miUTF32 => 18,
);

# Matrix types

use constant {
    mxCELL_CLASS => 1,
    mxSTRUCT_CLASS => 2,
    mxOBJECT_CLASS => 3,
    mxCHAR_CLASS => 4,
    mxSPARSE_CLASS => 5,
    mxDOUBLE_CLASS => 6,
    mxSINGLE_CLASS => 7,
    mxINT8_CLASS => 8,
    mxUINT8_CLASS => 9,
    mxINT16_CLASS => 10,
    mxUINT16_CLASS => 11,
    mxINT32_CLASS => 12,
    mxUINT32_CLASS => 13,
    mxINT64_CLASS => 14,
    mxUINT64_CLASS => 15,
};

my %mx = reverse (
    mxCELL_CLASS => 1,
    mxSTRUCT_CLASS => 2,
    mxOBJECT_CLASS => 3,
    mxCHAR_CLASS => 4,
    mxSPARSE_CLASS => 5,
    mxDOUBLE_CLASS => 6,
    mxSINGLE_CLASS => 7,
    mxINT8_CLASS => 8,
    mxUINT8_CLASS => 9,
    mxINT16_CLASS => 10,
    mxUINT16_CLASS => 11,
    mxINT32_CLASS => 12,
    mxUINT32_CLASS => 13,
    mxINT64_CLASS => 14,
    mxUINT64_CLASS => 15,
);

# See MATFile.pod for documentation

sub mi2word
{
    my ($type) = @_;
    return $names{$type};
}

# See MATFile.pod for documentation

sub mx2word
{
    my ($class) = @_;
    return $mx{$class};
}

# See MATFile.pod for documentation

sub read_matfile
{
    my ($file_name) = @_;
    validate_file_name ($file_name);
    my $obj = Data::MATFile->new ($file_name);
    $obj->read_file_header ();

    again:
    my $ok = $obj->read_object ();
    if ($ok) {
        goto again;
    }

    return $obj;
}

# Private functions below this.

=head2 read_file_header

    $obj->read_file_header ();

Read the header of the MAT-File. This stores the "descriptive text" of
the file in a field

    $obj->{descriptive_text}

It also sets the endian-ness of the file.

=cut

sub read_file_header
{
    my ($obj) = @_;
    $obj->{descriptive_text} = $obj->read_bytes (116, 1);
    if ($obj->{verbose}) {
        print "The descriptive text is \"$obj->{descriptive_text}\".\n";
    }
    $obj->{subsys_data_offset} = $obj->read_bytes (8);
    # Header Flag Fields
    my $hff;
    $hff = $obj->read_bytes (4, 1);
    my ($v, $e) = unpack ("SS", $hff);
    if ($v != 0x0100) {
        carp "$obj->{file_name}: Unknown version $v";
    }
    $obj->set_endianness ($e);
    if ($obj->{verbose}) {
        print "Successfully read file header.\n";
    }
    return;
}

=head2 validate_file_name

    validate_file_name ('file-name.mat');

Given a file name, make sure that it is not an empty string and that
the file exists. This does not return a value since it dies on error.

=cut

sub validate_file_name
{
    my ($file_name) = @_;
    if (! $file_name) {
        croak "supply a file name";
    }
    if (! -f $file_name) {
        croak "no such file '$file_name'";
    }
    return;
}

=head2 new

    my $obj = Data::MATFile->new ('file-name.mat');

Start a new object for reading the specified file name. The file name
must be supplied, but is not checked (the checking is part of
L</read_matfile>).

=cut

sub new
{
    my ($package, $file_name) = @_;
    my $obj = {
        file_name => $file_name,
    };
    bless $obj;
    $obj->{verbose} = $VERBOSE;
    if ($obj->{verbose}) {
        print <<'EOF';
 __     __        _                            _     _           _   
 \ \   / /__ _ __| |__   ___  ___  ___    ___ | |__ (_) ___  ___| |_ 
  \ \ / / _ \ '__| '_ \ / _ \/ __|/ _ \  / _ \| '_ \| |/ _ \/ __| __|
   \ V /  __/ |  | |_) | (_) \__ \  __/ | (_) | |_) | |  __/ (__| |_ 
    \_/ \___|_|  |_.__/ \___/|___/\___|  \___/|_.__// |\___|\___|\__|
                                                  |__/               

EOF
        print "File name is $obj->{file_name}.\n";
    }
    $obj->open_matfile ();
    return $obj;
}

=head2 open_matfile

    $obj->open_matfile ();

Open the MAT-File for reading and set up the file handle in the object.

=cut

sub open_matfile
{
    my ($obj) = @_;
    open ($obj->{fh}, "<:raw", $obj->{file_name});
    if (! $obj->{fh}) {
        # Don't use $obj->error since file not open yet.
        croak "could not open $obj->{file_name}: $!";
    }
    return;
}

=head2 set_endianness

    $obj->set_endianness ($flag);

Set the endian-ness of C<$obj> from C<$flag>, which is part of the
header, as read in L</read_file_header>.

=cut

sub set_endianness
{
    my ($obj, $flag) = @_;
    my $e = chr ($flag / 0x100) . chr ($flag % 0x100);
    if ($e eq 'MI') {
        $obj->{endian} = 0;
    }
    elsif ($e eq 'IM') {
        $obj->{endian} = 1;
        $obj->error ("Opposite endian-ness files are not supported");
    }
    else {
        $obj->error ("Endian-ness flag $flag of $obj->{file_name} was not parsed");
    }
    if ($obj->{verbose}) {
        print "Endian-ness of input file is $obj->{endian}.\n";
    }
    return;
}

sub set_data
{
    my ($obj, $data) = @_;
    $obj->{input_data} = $data;
}

# Data-reading functions

=head2 read_object

    my $array = $obj->read_object ();

Read an object from the file.

=cut

sub read_object
{
    my ($obj) = @_;
    die "bad call" if wantarray != 0;
    my ($type, $n_bytes, $data) = $obj->read_data_header ();
    if ($obj->{eof}) {
        return undef;
    }
    if ($type == miCOMPRESSED) {
#	print "Oh, you have $n_bytes of data.\n";
	my $cdata = $obj->read_bytes ($n_bytes);
	my $uncdata = gunzip ($cdata);
	$obj->set_data ($uncdata);
#	print "Read again as uncompressed.\n";
	my $value = $obj->read_object ();
	$obj->set_data (undef);
	return $value;
    }
    elsif ($type == miMATRIX) {
	return $obj->read_matrix ($n_bytes, $data);
    }
    else {
	my $name = $names{$type};
	if (! defined $name) {
	    $name = 'unknown';
	}
        $obj->error ("cannot handle non-matrix data of type $name here");
    }
    return undef;
}

sub read_matrix
{
    my ($obj, $n_bytes, $data) = @_;
    if ($obj->{verbose}) {
        print <<'EOF';
                           
   __ _ _ __ _ __ __ _ _   _ 
  / _` | '__| '__/ _` | | | |
 | (_| | |  | | | (_| | |_| |
  \__,_|_|  |_|  \__,_|\__, |
                       |___/ 

EOF
    }
    my ($class) = $obj->read_array_flags ();
    # Flag for numeric classes.
    my $numeric = $obj->is_numeric ($class);
    my @dim = $obj->get_array_dimensions ();
    my $name = $obj->get_array_name ();

    # This is the return value.  It has to be stored in this
    # convoluted way because we need to store things like the
    # "complex" flag and the name of the matrix.

    my $matrix = {
        dimensions => \@dim,
        name => $name,
        class => $class,
    };

    # Handle the different possible types of matrix data.

    if ($numeric) {
        my $numbers = $obj->get_numeric_array ($class, \@dim);
        $matrix->{array} = $numbers,
    }
    elsif ($class == mxSTRUCT_CLASS) {
        my $field_names = $obj->read_field_names ();
        for (0..$#$field_names) {
            my $name = $field_names->[$_];
            if (! $name) {
                $obj->error ("no name for element $_");
            }
            my $subarray = $obj->read_matrix ();
            $matrix->{array}->{$name} = $subarray;
        }
    }
    elsif ($class == mxCELL_CLASS) {
        my $cells = $obj->read_cells (\@dim);
        $matrix->{array} = $cells;
    }
    elsif ($class == mxCHAR_CLASS) {
        my $chars = $obj->read_chars ();
        if ($obj->{verbose}) {
            print "$_: $chars\n";
        }
        $matrix->{array} = $chars;
    }
    else {

        # Unsupported matrix class.

        $obj->error ("cannot handle $mx{$class} matrices");
    }

    if (! defined $matrix->{array}) {
        die "error: empty data section of matrix";
    }
    $obj->{data}->{$matrix->{name}} = $matrix;
    return $matrix;
}

=head2 read_chars

    my $chars = $obj->read_chars ();

Read the characters from a cell matrix consisting of characters.

=cut

sub read_chars
{
    my ($obj) = @_;
    my ($type, $n_bytes, $data) = $obj->read_data_header ();
    if (! $data) {
        $data = $obj->read_bytes ($n_bytes);
    }
    my @chars = unpack ("ax" x ($n_bytes/2), $data);
    my $chars = join '', @chars;
    return $chars;
}

=head2 read_cells

    $obj->read_cells ($dim);

Read the cells of a mxCELL_CLASS submatrix.

=cut

sub read_cells
{
    my ($obj, $dim) = @_;
    die "bad call" if wantarray () != 0;
    my $n_cells = n_from_dim ($dim);
    my @cells;
    for (1..$n_cells) {
        my $cell = $obj->read_matrix ();
        push @cells, $cell;        
    }
    return \@cells;
}

=head2 read_array_flags

     my ($class) = $obj->read_array_flags ();

Read the Array Flags. Currently this only returns the class of the
array. For the sake of future expansion, always call in list context.

=cut

sub read_array_flags
{
    my ($obj) = @_;
    my ($type, $n_bytes, $data) = $obj->read_data_header ();
    if ($type != miUINT32) {
        $obj->error ("bad type $type for array flags");
    }
    if ($n_bytes != 8) {
        $obj->error ("array flags $n_bytes not 8 bytes");
    }
    my $f = $obj->read_bytes (8);
    my ($x, $y) = unpack ("LL", $f);
    my $flags = int ($x / 0x100) % 0x100;
    my $complex = $flags & 0x10;
    if ($obj->{verbose}) {
        if ($complex) {
            print "Is complex.\n";
        }
        else {
            print "Is not complex.\n";
        }
    }
    if ($complex) {
        $obj->error ("Cannot handle complex matrices");
    }
    my $class = $x % 0x100;
    if ($class > 15) {
        carp "Unknown matrix class $class";
    }
    if ($obj->{verbose}) {
        print "Class is $mx{$class}.\n";
    }
    return ($class);
}

=head2 read_field_names

    my $names = $obj->read_field_names ();

Read the field names of a "Structure MAT-File Data Element".

=cut

sub read_field_names
{
    my ($obj) = @_;
    if ($obj->{verbose}) {
        print "Reading field names of a structure.\n";
    }
    my ($type, $n_bytes, $data) = $obj->read_data_header ();
    if ($type != miINT32) {
        $obj->error ("wrong type $type for field name length");
    }
    if ($n_bytes != 4) {
        $obj->error ("wrong number $n_bytes for field name length");
    }
    if (! defined $data) {
        $obj->error ("Field name length is not provided");
    }
    my $field_name_length = unpack ("l", $data);
    if ($obj->{verbose}) {
        print "Field name length is $field_name_length.\n";
    }
    ($type, $n_bytes, $data) = $obj->read_data_header ();
    if ($type != miINT8) {
        $obj->error ("wrong type $type for field names");
    }
    my $n_names = $n_bytes / $field_name_length;
    if ($n_names != int ($n_names)) {
        $obj->error ("name field bytes $n_bytes not multiple of $field_name_length");
    }
    # The list of extracted names.
    my @names;
    for (1..$n_names) {
        my $name = $obj->read_bytes ($field_name_length);
        $name = unpack ("A*", $name);
        if ($obj->{verbose}) {
            print "Name: \"$name\"\n";
        }
        push @names, $name;
    }
    return \@names;
}

=head2

    if (is_numeric ($class)) {

A true or false routine which returns true if C<$class> is a numeric
matrix type and false if not.

=cut

sub is_numeric
{
    my ($obj, $class) = @_;
    my $numeric;
    if ($class == mxDOUBLE_CLASS ||
        $class == mxSINGLE_CLASS ||
	$class == mxINT8_CLASS ||
	$class == mxUINT8_CLASS ||
	$class == mxINT16_CLASS ||
	$class == mxUINT16_CLASS ||
	$class == mxINT32_CLASS ||
	$class == mxUINT32_CLASS) {
        $numeric = 1;
    }
    if ($obj->{verbose}) {
        if ($numeric) {
            print "Numeric.\n";
        }
        else {
            print "Non-numeric.\n";
        }
    }
    return $numeric;
}

=head2 get_numeric_array

    $array = $obj->get_numeric_array ($class, \@dim);

Given an array class for numeric data, C<$class>, and the dimensions
of the array, C<@dim>, this returns an array reference of numerical
data read from the file handle and arranged into a multidimensional
array using C<@dim>.

=cut 

sub get_numeric_array
{
    my ($obj, $class, $dim) = @_;
    my ($type, $n_bytes, $data) = $obj->read_data_header ();
    my $numbers;
    if ($type == miDOUBLE) {
        if ($class != mxDOUBLE_CLASS) {
            $obj->error ("Mismatch of class and data type");
        }
        $numbers = $obj->get_doubles ($n_bytes);
    }
    else {
        if (! $data) {
            $data = $obj->read_bytes ($n_bytes);
        }
        if ($type == miINT8) {
            $numbers = [unpack ("c*", $data)];
        }
        elsif ($type == miUINT8) {
            $numbers = [unpack ("C*", $data)];
        }
        elsif ($type == miINT16) {
            $numbers = [unpack ("s*", $data)];
        }
        elsif ($type == miUINT16) {
            $numbers = [unpack ("S*", $data)];
        }
        elsif ($type == miINT32) {
            $numbers = [unpack ("l*", $data)];
        }
        elsif ($type == miUINT32) {
            $numbers = [unpack ("L*", $data)];
            print "NUMBERS @$numbers\n";
        }
        else {
            die "$names{$type} not supported";
        }
    }
    return $obj->make_n_d_array ($dim, $numbers);
}

=head2 make_n_d_array

    my $array = make_n_d_array (\@dim, \@numbers);

Make an n-dimensional array with dimensions from C<@dim> with the
values in C<@numbers>. For example, if C<@dim = (2, 3)> and

    @numbers = (1, 2, 3, 4, 5, 6),

the return value of this is an array reference formatted as follows:

    $array = [[1, 2, 3], [4, 5, 6]];

using the values in C<@dim>.

=cut

sub make_n_d_array
{
    my ($obj, $dim, $numbers) = @_;
    my $n = n_from_dim ($dim);
    if (scalar @$numbers != $n) {
        $obj->error ("Got $n numbers, expected ". (scalar @$numbers));
    }
    my $m = [];

    # For the two-D case, we can zip through the matrix:

    if (@$dim == 2) {
        my $d = $dim->[0];
        for my $i (0..$n - 1) {
            my $j = int ($i / $d);
            my $k = $i % $d;
            $m->[$k][$j] = $numbers->[$i];
        }
    }
    else {

        #  _                                           _      
        # | |__   ___   __ _ _   _ ___    ___ ___   __| | ___ 
        # | '_ \ / _ \ / _` | | | / __|  / __/ _ \ / _` |/ _ \
        # | |_) | (_) | (_| | |_| \__ \ | (_| (_) | (_| |  __/
        # |_.__/ \___/ \__, |\__,_|___/  \___\___/ \__,_|\___|
        #              |___/                                  

        # This is mega-slow and totally insane 

        for my $i (0..$n - 1) {
            my @i;
            my $ij = $i;
            for my $j (0..$#$dim) {
                my $d = $dim->[$j];
                $i[$j] = $ij % $d;
                $ij /= $d;
            }
            my $stuff = '$m->[' . join ('][', @i) . ']';
            $stuff = "$stuff=$numbers->[$i]";
            #            print "@i $stuff\n";
            
            # Horrors!

            eval $stuff;
        }
    }
    # for (@$m) {
    #     print "@$_\n";
    # }
    return $m;
}

=head2 n_from_dim

    my $n = n_from_dim (\@dim);

Given the dimensions of a matrix, return the total number of
elements in the matrix.

=cut

sub n_from_dim
{
    my ($dim) = @_;
    my $n = 1;
    for (@$dim) {
        $n *= $_;
    }
    return $n;
}

=head2 get_doubles

    my $doubles = $obj->get_doubles ($n_bytes);

Get C<$n_bytes / 8> doubles and put them in an array.

=cut

sub get_doubles
{
    my ($obj, $n_bytes) = @_;
    if ($n_bytes % 8 != 0) {
        $obj->error ("Bad byte count $n_bytes for doubles");
    }
    my $n_doubles = $n_bytes / 8;
    my $bytes = $obj->read_bytes ($n_bytes);
    my @doubles;
    for (0..$n_doubles - 1) {
        my $double = parse_double (substr ($bytes, $_ * 8, 8));
        if ($obj->{verbose}) {
            printf "Got a $double.\n";
        }
        push @doubles, $double;
    }
    return \@doubles;
}

=head2 parse_double

    my $double = parse_double ($bytes);

This converts the MAT-File double (eight bytes, the IEEE 754 "double
64" format) into a Perl floating point number.

=cut

# http://www.perlmonks.org/bare/?node_id=703222

sub double_from_hex { unpack 'd', scalar reverse pack 'H*', $_[0] }

use constant POS_INF => double_from_hex '7FF0000000000000';
use constant NEG_INF => double_from_hex 'FFF0000000000000';
use constant NaN     => double_from_hex '7FF8000000000000';

sub parse_double
{
    my ($bytes) = @_;
    my ($bottom, $top) = unpack ("LL", $bytes);
    # Reference:
    # http://en.wikipedia.org/wiki/Double_precision_floating-point_format

    # Eight zero bytes represents 0.0.
    if ($bottom == 0) {
        if ($top == 0) {
            return 0;
        }
        elsif ($top == 0x80000000) {
            return -0;
        }
        elsif ($top == 0x7ff00000) {
            return POS_INF;
        }
        elsif ($top == 0xfff00000) {
            return NEG_INF;
        }
    }
    elsif ($top == 0x7ff00000) {
        return NaN;
    }
    my $sign = $top >> 31;
#    print "$sign\n";
    my $exponent = (($top >> 20) & 0x7FF) - 1023;
#    print "$exponent\n";
    my $e = ($top >> 20) & 0x7FF;
    my $t = $top & 0xFFFFF;
#    printf ("--> !%011b%020b \n--> %032b\n", $e, $t, $top);
    my $mantissa = ($bottom + ($t*(2**32))) / 2**52 + 1;
#    print "$mantissa\n";
    my $double = (-1)**$sign * 2**$exponent * $mantissa;
    return $double;
}

=head2 get_array_name

    my $name = $obj->get_array_name ();

Get the name of an array from the next point in the file. If the array
does not have a name, the return value is the undefined value.

=cut

sub get_array_name
{
    my ($obj) = @_;
    if ($obj->{verbose}) {
        print "Trying to read the array's name.\n";
    }
    my ($type, $n_bytes, $data) = $obj->read_data_header ();
    if ($type != miINT8) {
        $obj->error ("bad type $type for array name");
    }
    # Arrays within a struct have name fields with zero bytes.
    if ($n_bytes == 0) {
        return undef;
    }
    if (! $data) {
        $data = $obj->read_bytes ($n_bytes);
    }
    # Remove trailing bytes from the string.
    $data = substr $data, 0, $n_bytes;
    if ($obj->{verbose}) {
        print "The array's name is \"$data\".\n";
    }
    return $data;
}

=head2 get_array_dimensions

    my @dim = $obj->get_array_dimensions ();

Get the dimensions of an array from the file, as an array. Matlab
arrays always have at least two dimensions, so @dim is at least size
2.

=cut

sub get_array_dimensions
{
    die "Bad call" if (! wantarray);
    my ($obj) = @_;
    my ($type, $n_bytes, $data) = $obj->read_data_header ();
    if ($type != miINT32) {
        $obj->error ("bad type $type for array dimensions");
    }
    my $dim = $obj->read_bytes ($n_bytes);
    my @dim = unpack ("L" x ($n_bytes / 4), $dim);
    if ($obj->{verbose}) {
        print "The array's dimensions are @dim.\n";
    }
    return @dim;
}

=head2 read_data_header

    my ($type, $n_bytes, $data) = $obj->read_data_header ();

Read an eight-byte data header from the file and parse it.

=cut

sub read_data_header
{
    my ($obj) = @_;
    if ($obj->{verbose}) {
	print "Reading data header.\n";
    }
    my $h = $obj->read_bytes (8);
    if ($obj->{eof}) {
        return;
    }
    my ($type, $n_bytes, $data) = $obj->parse_data_header ($h);
    return ($type, $n_bytes, $data);
}


=head2 parse_data_header

    my ($type, $n_bytes, $data) = $obj->parse_data_header ($h);

Parse the data header in C<$h> without reading from the file
itself. C<$h> must be eight bytes long.

This takes an eight-byte data header and parses out the type and the
number of bytes from it. Should this be a Small Data Element Format
piece of data, it will also return the value in C<$data>. If C<$data>
is undefined, that indicates that it was not a Small Data Element
Format piece of data, so the data will need to be read separately.

=cut

sub parse_data_header
{
    my ($obj, $h) = @_;
    if ($obj->{verbose}) {
	print "Parsing data header.\n";
    }
    if (length $h != 8) {
        $obj->error ("Bad length " . (length $h) . " for data header");
    }
    my $type;
    my $n_bytes;
    ($type, $n_bytes) = unpack ("LL", $h);
    my $data;
    my $sdef = int ($type / 0x10000);
    if ($sdef) {
        # Small Data Element Format
        if ($obj->{verbose}) {
            print "Small Data Element Format with $sdef bytes.\n";
        }
        $n_bytes = $sdef;
        $type = $type % 0x10000;
        (undef, $data) = unpack ("a4a4", $h);
        # Remove padding bytes
        $data = substr ($data, 0, $n_bytes);
    }
    if ($type > 18) {
        $obj->warning ("Unknown data type $type");
    }
    if ($obj->{verbose}) {
        printf "%X: Type and number of bytes are $names{$type} and %u.\n",
            tell ($obj->{fh}) - 8, $n_bytes;
    }
    return ($type, $n_bytes, $data);
}

# Basic byte reader

=head2 read_bytes

    my $bytes = $obj->read_bytes ($n_bytes);

Read C<$n_bytes> bytes from the MAT-File. It rounds the number up to
an eight-byte multiple unless a second, true, argument is given:

    my $bytes = $obj->read_bytes ($n_bytes, 1);

=cut

sub read_bytes
{
    my ($obj, $n, $no_pad) = @_;
    my $r;
    my $nbytes = $n;
    if ($obj->{eof}) {
        croak "attempt to read beyond end of $obj->{file_name}";
    }
    if ($obj->{verbose}) {
        if ($no_pad) {
            print "Not padding to eight-byte boundary.\n";
        }
    }
    my $padded;
    # Round up to eight-byte boundary.
    if (! $no_pad && $n % 8 != 0) {
        $nbytes += (8 - $n % 8);
        $padded = 1;
    }

    # Read from uncompressed data if available.

    if ($obj->{input_data}) {
	print "Reading $nbytes ($n) from uncompressed data.\n";
	my $has = length ($obj->{input_data});
	if ($nbytes > $has) {
	    $obj->error ("Cannot read $nbytes, only have $has left");
	}
	$r = substr ($obj->{input_data}, 0, $nbytes);
	# Remove $nbytes bytes from input_data.
	$obj->{input_data} = substr ($obj->{input_data}, $nbytes);
    }
    else {
	my $nread = read ($obj->{fh}, $r, $nbytes);
	if (! defined $nread) {
	    $obj->error ("could not read $n bytes: $!");
	}
	if ($nread == 0) {
	    $obj->{eof} = 1;
	}
	elsif ($nread != $nbytes) {
	    $obj->error ("Tried to read $n bytes and got $nread");
	}
    }
    # If the read data is padded, chop off the padding.
    if ($padded) {
        if ($obj->{verbose}) {
            print "Chopping padding to length $n.\n";
        }
        $r = substr ($r, 0, $n);
    }
    return $r;
}

# Error-handlers

=head2 error

    $obj->error ($message);

This is for errors during reading of the file.  A call to "croak" with
C<$message> and the current file location and name taken from C<$obj>.

=cut

sub error
{
    my ($obj, $message) = @_;
    $message = $obj->error_message ($message);
    croak $message;
}

=head2 warning

    $obj->warning ($message);

This is for warnings during reading of the file. A call to "carp" with
C<$message> and the current file location and name taken from C<$obj>.

=cut

sub warning
{
    my ($obj, $message) = @_;
    $message = $obj->error_message ($message);
    carp $message;
}

=head2 error_message

    my $message = $obj->error_message ($message);

Make an error message with the current byte and file name.

=cut

sub error_message
{
    my ($obj, $message) = @_;
    my $byte = tell ($obj->{fh});
    my $hexbyte = sprintf ("%X", $byte);
    $message = "$message near byte $byte (0x$hexbyte) of $obj->{file_name}"; 
    return $message;
}

1;


package Astro::FITS::CFITSIO::Simple;

# ABSTRACT: read and write FITS tables

use 5.008002;
use strict;
use warnings;

require Exporter;

use Params::Validate qw/ :all /;

use Carp;

use PDL;

use Astro::FITS::CFITSIO qw/ :constants /;
use Astro::FITS::CFITSIO::CheckStatus;
use Astro::FITS::CFITSIO::Simple::Table qw/ :all /;
use Astro::FITS::CFITSIO::Simple::Image qw/ :all /;


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Astro::FITS::CFITSIO::Table ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [ qw(
          rdfits
        ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.20';

# cheap and dirty clean up object so that we can maintain
# return contexts in rdfits and its delegates by having
# cleanup done during object destruction
{
    package Astro::FITS::CFITSIO::Simple::Cleanup;

    sub new { my $class = shift; bless {@_}, $class }
    sub set { $_[0]->{ $_[1] } = $_[2] }
    sub DESTROY {
        my $s = shift;
        tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';
        $s->{fptr}->perlyunpacking( $s->{packing} )
          if defined $s->{packing};
        $s->{fptr}->movabs_hdu( $s->{hdunum}, undef, $status )
          if defined $s->{hdunum};
    }
}



# HDU types we recognize
our %HDUType = (
    img    => IMAGE_HDU,
    image  => IMAGE_HDU,
    binary => BINARY_TBL,
    bintbl => BINARY_TBL,
    ascii  => ASCII_TBL,
    any    => ANY_HDU,
    table  => undef,        # the CFITSIO flags aren't really bits
);

sub validHDUTYPE { exists $HDUType{ lc $_[0] } }
sub validHDUNUM  { $_[0] =~ /^\d+$/ && $_[0] > 0 }



# these are the Params::Validate specifications for rdfits
# they are specified separately here, so that parameters
# for _rdfitsTable and _rdfitsImage can be split out
# from the main option hash

our %rdfits_spec = (
    extname => { type => SCALAR, optional => 1 },
    extver  => {
        type    => SCALAR,
        depends => 'extname',
        default => 0
    },
    hdunum => {
        type      => SCALAR,
        callbacks => { 'illegal HDUNUM' => \&validHDUNUM, },
        optional  => 1
    },
    hdutype => {
        type      => SCALAR,
        callbacks => { 'illegal HDU type' => \&validHDUTYPE, },
        default   => 'any',
        optional  => 1
    },
    resethdu => { type => SCALAR, default => 0 },
);

sub rdfits {

    # strip off the options hash
    my $opts = 'HASH' eq ref $_[-1] ? pop : {};

    # first arg is fitsfilePtr or filename
    my $input = shift;

    croak( "input must be a fitsfilePtr or a file name\n" )
      unless defined $input
      && ( UNIVERSAL::isa( $input, 'fitsfilePtr' ) || !ref $input );


    # rdfits is a dispatch routine; we need to filter out the options
    # for the delegates (and vice versa).  final argument validation
    # is done by the the delegates

    # shallow copy, then delete non-rdfits options.
    my %rdfits_opts = %{$opts};
    delete @rdfits_opts{
        grep { !exists $rdfits_spec{ lc( $_ ) } }
          keys %rdfits_opts
    };

    # shallow copy, then delete rdfits options
    my %delegate_opts = %{$opts};
    delete @delegate_opts{ keys %rdfits_opts };

    # if there are additional arguments, guess that we're being
    # asked for some columns, and set the requested HDUTYPE to table
    $rdfits_opts{hdutype} = 'table' if @_;

    # validate arguments
    my %opt = validate_with(
        params         => [ \%rdfits_opts ],
        normalize_keys => sub { lc $_[0] },
        spec           => \%rdfits_spec
    );



    # CFITSIO file pointer
    my $fptr;

    tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

    my $cleanup;

    # get CFITSIO file pointer
    if ( UNIVERSAL::isa( $input, 'fitsfilePtr' ) ) {

        $fptr = $input;

        $cleanup = Astro::FITS::CFITSIO::Simple::Cleanup->new(
            fptr    => $fptr,
            packing => $fptr->perlyunpacking
        );

        if ( $opt{resethdu} ) {
            $fptr->get_hdu_num( my $hdunum );
            $cleanup->set( hdunum => $hdunum );
        }

    }
    else {
        $fptr = Astro::FITS::CFITSIO::open_file( $input, READONLY,
            $status = "could not open FITS file '$input'" );
    }

    # we're not unpacking;
    $fptr->perlyunpacking( 0 );

    # read in all of the extensions
    croak( "slurp not yet implemented!\n" )
      if $opt{slurp};

    # read in just one
    my $hdutype;

    # HDU specified by name
    if ( exists $opt{extname} ) {
        $fptr->movnam_hdu( ANY_HDU, $opt{extname}, $opt{extver},
            $status = "could not move to HDU '$opt{extname}:$opt{extver}'" );

        $fptr->get_hdu_type( $hdutype, $status );

        croak( "requested extension does not match requested HDU type\n" )
          unless match_hdutype( $opt{hdutype}, $hdutype );
    }

    # HDU specified by number?
    elsif ( exists $opt{hdunum} ) {
        $fptr->movabs_hdu( $opt{hdunum}, $hdutype, $status );

        croak( "requested extension does not match requested HDU type\n" )
          unless match_hdutype( $opt{hdutype}, $hdutype );
    }

    # first recognizable one
    else {
        # lazy; let CheckStatus do the work.
        eval {
            until ( $status ) {
                $fptr->get_hdu_type( $hdutype, $status );

                # check that we're in an actual image, i.e. NAXIS != 0
                if ( IMAGE_HDU == $hdutype ) {
                    $fptr->get_img_dim( my $naxis, $status );
                    next unless $naxis;
                }
                last if match_hdutype( $opt{hdutype}, $hdutype );

            }
            continue {
                $fptr->movrel_hdu( 1, $hdutype, $status );
            }
        };

        # ran off end of file
        croak( "unable to find a matching HDU to read\n" )
          if BAD_HDU_NUM == $status;

        # all other errors
        croak $@ if $@;
    }

    # update args.
    unshift @_, $fptr;

    # add the options for the delegate
    push @_, \%delegate_opts;

    # dispatch. we use the dispatch goto here to keep croak's etc. at the
    # correct level and to maintain the calling context.

    if ( BINARY_TBL == $hdutype || ASCII_TBL == $hdutype ) {
        _rdfitsTable( @_ );
    }
    elsif ( IMAGE_HDU == $hdutype ) {
        _rdfitsImage( @_ );
    }
    else {
        croak( "internal error. bizarre hdutype = $hdutype\n" );
    }

}

# a thin front end for reading in a table

sub rdfitstbl {
    # make shallow copy of passed options hash (or create one)
    my %opt = 'HASH' eq ref $_[-1] ? %{ pop @_ } : ();

    # force the HDU to match a table
    $opt{hdutype} = 'table';

    # read only one HDU
    delete $opt{slurp};

    # make sure only the input file is in there.
    croak( "too many arguments to rdfitstbl\n" )
      if @_ > 1;

    # attach our new options hash
    push @_, \%opt;

    # do the whole shebang; pretend we were never here.
    goto &rdfits;
}

# a thin front end for reading in an image

sub rdfitsimg {
    # make shallow copy of passed options hash (or create one)
    my %opt = 'HASH' eq ref $_[-1] ? %{ pop @_ } : ();

    # force the HDU to match a table
    $opt{hdutype} = 'image';

    # read only one HDU
    delete $opt{slurp};

    # attach our new options hash
    push @_, \%opt;

    # do the whole shebang; pretend we were never here.
    goto &rdfits;
}

sub match_hdutype {
    my ( $req, $actual ) = @_;

    return ( BINARY_TBL == $actual || ASCII_TBL == $actual )
      if 'table' eq $req;

    my $reqtype = $HDUType{$req};

    return 1 if ANY_HDU == $reqtype;

    return 1 if $reqtype == $actual;


    0;
}

#
# This file is part of Astro-FITS-CFITSIO-Simple
#
# This software is Copyright (c) 2008 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Pete Ratzlaff Smithsonian Astrophysical Observatory HDU
Subtractive defdtype dtype dtypes extname extver hdr hdunum hdutype idx
lowercased ninc nullval rdfits rdfitsimg rdfitstbl resethdu rethash rethdr
retinfo rfilter tieing unary

=head1 NAME

Astro::FITS::CFITSIO::Simple - read and write FITS tables

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use Astro::FITS::CFITSIO::Simple qw/ rdfits /;

  # read in an image
  $pdl = rdfits( $file );

  # read in some columns from a table
  %pdls = rdfits( $file );

  # read just the columns you want
  @pdls = rdfits( $file, @cols );

  # and many more ...

=head1 DESCRIPTION

This module presents an uncomplicated interface to reading (and
eventually writing) FITS files with the B<CFITSIO> library.  It
attempts to perform the intuitive action when left to its own devices,
but much of its behavior can be controlled by an application.

=head2 Reading FITS files

B<rdfits> reads numeric FITS data into PDL objects (piddles).  String
data (from tables) are stored in ordinary Perl arrays; references to
those are returned.  It recognizes image (primary or extension) and
binary or ASCII tables.

B<rdfits> pays attention to what it is asked to read as well
as the context in which it was called (i.e., whether an array or a scalar
was requested).  The default behavior when reading data from a single
HDU (the default) is as follows:

=over 8

=item *

An image is always returned as a single piddle, regardless of the
calling context.

  $img = rdfits( 'image.fits' );

=item *

Table data are returned as a hash if no column names are specified.

  %table = rdfits( 'table.fits' );

In this case all columns are returned.  However, if a list of column
names prefixed by the C<-> character is given, these
columns will I<not> be returned.  For example:

  %table = rdfits( 'table.fits', qw/ -status -boring / );

"Subtractive" column designations may not be mixed with "additive"
column designations.

=item *

Table data are returned as a list if column names are specified and
B<rdfits> was called in an array (list) context.

  @coldata = rdfits( 'table.fits', 'col1', 'col2' );

=item *

If a single column is read and B<rdfits> is called in a scalar
context, the data are returned as a scalar (piddle or arrayref,
depending upon data type).

  $coldata = rdfits( 'table.fits', 'col1' );

=back

Some of this behavior may be changed using the C<rethash> option.

Normally B<rdfits> maps the FITS column type (double, long, etc) to
the best matched PDL type.  This may be overridden (for instance to
promote floats to doubles) using the C<dtypes> or C<defdtype> options.
Bit columns are a bit different.  (See L</Reading Bit Data>).

B<rdfits> can optionally return the full FITS header.  If an image is
read, the resultant piddle's header is set to a hash tied to a
Astro::FITS::Header object.  For most intents and purposes, this is
just like an ordinary piddle header.

  $pdl = rdfits( 'image.fits' );
  print $pdl->gethdr->{HDUNAME};

Retrieving the header for table data is a little more complicated.  See the
B<rethdr> option below for more information.

See L<Astro::FITS::Header> for more information on its representation
of FITS headers.

=head3 Reading Bit Data

Table data with type BIT are by default mapped onto a PDL type which
best matches the FITS element size, with the packing of the bits
preserved. The user may override this type using the C<dtypes> or
C<defdtype> options (see the description under L</Table Options>
below).

Another option is to treat each bit as an independent quantity, with
each bit stored in its own piddle element.  This may be accomplished
by specifying the PDL type (via C<dtypes> or C<defdtype>) as the
string C<logical>.  Bits will then be stored as bytes, with each byte
representing a bit.

=head2 Functions

=over

=item rdfits

B<rdfits> takes a single mandatory parameter which is either a file
name or a B<CFITSIO> file pointer.  With no other information
provided, it reads data from the first available (and recognizable)
HDU.  If additional scalar values are provided, they are assumed to be
column names, and B<rdfits> will search only for tables.
The data are stored as described in L<Reading FITS files>.

B<rdfits> C<croak()'s> upon error.

B<rdfits>'s behavior can be controlled via a hashref passed in
as the last argument:

  rdfits($file, [...], \%opts );

There are three categories of options:  those which affect how
B<rdfits> finds an HDU to read; those which affect reading tables;
and those which affect reading of columns.

=over

=item HDU options

=over 8

=item extname

This may be set to the exact name of the HDU to read.

=item extver

This may be set to the version of the HDU to read.  It requires
that C<extname> be set as well.

=item hdunum

The index of the HDU in the file.  This may also be appended to
the file name in brackets, i.e. C<file[1]>.

=item hdutype

The type of HDU to read.  This may be one of the following strings:

    img image      - read an image
    binary bintbl  - read a binary table
    ascii          - read an ascii table
    table          - read any type of table
    any            - read any type of data

If a particular HDU is requested and the HDU type doesn't match,
B<rdfits> will croak.

=item resethdu

This takes a boolean value.  If true, and B<rdfits> was passed a
CFITSIO file pointer, the HDU pointer is stored and reset just before
B<rdfits> returns.  Defaults to false.

=back

=item Table Options

These options are accepted only when reading tables.  They will cause
an error otherwise.

=over 8

=item dtypes

=item defdtype

Normally, B<rdfits> will create the best fit PDL type for each column
read.  A default datatype for all columns can be set with C<defdtype>.
Individual columns' datatypes can be set with C<dtypes>.

C<defdtype> takes a single value, a B<PDL::Type> object.

   %data = rdfits( $file, { defdtype => double } );

C<dtypes> takes a reference to a hash whose keys are the column names
and whose values are C<PDL::Type> objects of the type wanted. For
example:

  ($a,$b,$c) =
    rdfits( $file, qw/ a b c /,
             { dtypes=>{ a=>float, c=>short } } );

This will force the PDL type of C<$a> to float, and C<$c> to short,
while choosing the best match datatype for C<$b>. It is not possible
for the user to specify dtypes for C<LOGICAL> and C<ASCII> type
columns.  C<BIT> columns are special; see L</Reading Bit Data> above.

=item ninc

The number of rows to read incrementally. By default, this number is
set according to C<fits_get_rowsize()> for the table being read.  This
is best left unset.

=item nullval

The value with which to fill in null data values.  If B<PDL> has been
built with bad value support, it defaults to the bad value for the
data type.  If not, it defaults to C<0>, which signals CFITSIO to
ignore null pixels.

=item rethash

  %data = rdfits('foo.fits', @cols, { rethash=>1 });

Normally when B<rdfits> is invoked with a list of columns to read, it
returns a list of piddles.  This Boolean option indicates that it
should return a hash (not a hashref) whose keys are the lower-cased
column names with the corresponding piddles for values.  This is the
default mode if no columns are specified.

=item rethdr

This Boolean option indicates that the HDU's header should be returned
as well as the data.

=over

=item *

If the data are returned in a list, the header will be the first
element of the list:

  ($hdr, @data ) =
    rdfits( 'foo.fits', @cols, { rethdr => 1 } );

The header is returned as an B<Astro::FITS::Header> object.

=item *

If the data are returned as a hash, an additional element in the hash
is added, with a key of C<_hdr>.

  # return the HDU header
  %hash = rdfits( 'foo.fits', @cols,
                  { rethash => 1, rethdr => 1 } );
  $hdr = $hash{_hdr};

The header is returned as an B<Astro::FITS::Header> object.

=item *

If a single column is requested, and it is returned in a scalar, the
returned piddle's header is set to a hash tied to a
B<Astro::FITS::Header> object.  For most intents and purposes, this
is just like an ordinary piddle header.

  $pdl = rdfits( 'foo.fits', $col,
                 { rethdr => 1 } );
  print $pdl->gethdr->{HDUNAME};

See L<Astro::FITS::Header> for more information on tieing to that class.

=back

=item retinfo

  %data = rdfits('foo.fits', @cols, { retinfo=>1 });

This option specifies that the data will be returned as a hash, keyed
off of the lowercased column names.  The values in the hash are
themselves hashes, with these elements:

=over

=item data

The data read from the file

=item idx

The index of the column in the file (unary based)

=item hdr

A hashref containing the FITS keywords which are specific to the
column (e.g., C<TTYPE>, C<TLMAX>, C<TUNIT>, etc.).  The keys for these
are the keyword names without the trailing column index.

=back

For example,

  %data = rdfitsTable('foo.fits', 'x', { retinfo => 1 });

might result in the equivalent hash of

  $data{'x'} = {
            idx  => 11,
            data => PDL...,
            hdr => {
                ttype => 'x',
                cuni  => 'deg',
                tlmax => '8.1925000E+03',
                tcdlt => '-1.3666666666667E-04',
                tunit => 'pixel',
                tform => '1E',
                tlmin => '5.0000000E-01',
                tcrvl => '3.2972102733253E+02',
                tcrpx => '4.0965000000000E+03',
                tctyp => 'RA---TAN',
            },
          };

=item rfilter

  %data = rdfitsTable('foo.fits', 'x',
                      { rfilter => 'X < 3' } });

This specifies a CFITSIO-style row filtering specification. Only the
rows matching this filter will be in the output variables.  The filter
has access to I<all> of the columns in the HDU, not just the ones
being read out.  This can radically reduce memory requirements if
a complicated row selection is made.

=item status

This option indicates that progress status should be output.
B<status> can take one of the following values:

=over

=item a scalar

If true, a progress bar is written to the standard error stream.
If the B<Term::ProgressBar> module is available, a fairly nice
one is emitted.  (The more primitive style may be forced by
setting the value to C<-1>).

=item a file glob

In this case output is sent to the specified file handle.

=item an object reference

If the object supports the B<print()> and B<flush()> methods, these
are called to output the progress status.  (Nice objects are,
for example IO::File objects).

=item a code reference

The code reference is called with two parameters: the number of rows
read, and the total number to be read.

=back

Typically output is produced approximately at 1% increment steps.

=back

=item Image Options

These options are accepted only when reading images.  They will cause
an error otherwise.

=over 8

=item dtype

Normally, B<rdfits> will create the best fit PDL type for the image
data.  The application can override the output datatype with this
option. The argument should be a C<PDL::Type> object. For example:

  $float_img = rdfits( $file, { dtype => float } );

=item nullval

The value with which to fill in null data values.  If B<PDL> has been
built with bad value support, it defaults to the bad value for the
data type.  If not, it defaults to C<0>, which signals CFITSIO to
ignore null pixels.

=back

=back

=item rdfitstbl

This is a thin wrapper around B<rdfits> which forces a single table
to be read.  It is equivalent to invoking B<rdfits> with the
options.

  { hdutype => 'table' }

It has the same calling convention as B<rdfits>.

=item rdfitsimg

This is a thin wrapper around B<rdfits> which forces a single table
to be read.  It is equivalent to invoking B<rdfits> with the
options

  { hdutype => 'image' }

It has the same calling convention as B<rdfits>.

=back

=for Pod::Coverage match_hdutype
validHDUNUM
validHDUTYPE

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-astro-fits-cfitsio-simple@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-FITS-CFITSIO-Simple

=head2 Source

Source is available at

  https://gitlab.com/djerius/astro-fits-cfitsio-simple

and may be cloned from

  https://gitlab.com/djerius/astro-fits-cfitsio-simple.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Astro::FITS::CFITSIO|Astro::FITS::CFITSIO>

=item *

L<PDL|PDL>

=item *

L<PDL::IO::FITS|PDL::IO::FITS>

=back

=head1 AUTHORS

=over 4

=item *

Diab Jerius <djerius@cpan.org>

=item *

Pete Ratzlaff

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

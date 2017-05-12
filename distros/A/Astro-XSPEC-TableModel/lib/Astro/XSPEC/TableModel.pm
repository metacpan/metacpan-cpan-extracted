# --8<--8<--8<--8<--
#
# Copyright (C) 2008 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::XSPEC::TableModel
#
# Astro::XSPEC::TableModel is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Astro::XSPEC::TableModel;

use 5.00800;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw( write_table );

use Carp;

use List::Util qw( max );

use Params::Validate qw( :all );

use Astro::FITS::CFITSIO qw( :constants );
use Astro::FITS::CFITSIO::CheckStatus;
use Astro::FITS::Header::Item;
use Astro::FITS::Header::CFITSIO;

our $VERSION = '0.01';

# this rule is too broad
## no critic ( ProhibitAccessOfPrivateData )

sub write_table {

    my @fields;

    my %opt = validate_with(
        params => \@_,
        spec   => {
            output => { type => SCALAR },
            model  => 1,
            units  => 1,
            additive => { type => BOOLEAN,  default => '0' },
            redshift => { type => BOOLEAN,  default => '0' },
            ipars    => { type => ARRAYREF },
            apars    => { type => ARRAYREF, default => [] },
            energy   => { type => ARRAYREF },
            keywords => { type => ARRAYREF, default => [] },
        },
        normalize_keys => sub { lc $_[0] },
    );

    tie my $err, 'Astro::FITS::CFITSIO::CheckStatus';

    my $fits =
      Astro::FITS::CFITSIO::create_file( "!$opt{output}",
        $err = "Error creating $opt{output}:" );

    # -------------------------------------
    # create PRIMARY HDU
    $fits->create_img( 8, 0, 0, $err = 'Error creating primary HDU: ' );
    _write_cards(
        $fits,
        $opt{keywords},
        [
            STRING =>
              CONTENT => 'MODEL',
            'spectrum file contains time intervals and event'
        ],
        [ STRING => MODLNAME => $opt{model}, 'Model name' ],
        [ STRING => MODLUNIT => $opt{units}, 'Model units' ],
        [
            LOGICAL =>
              REDSHIFT => $opt{redshift},
            'If true then redshift will be included as a parameter'
        ],
        [
            LOGICAL =>
              ADDMODEL => $opt{additive},
            'If true then this is an additive table model'
        ],
        [ STRING => HDUCLASS => 'OGIP', 'format conforms to OGIP standard' ],
        [
            STRING =>
              HDUCLAS1 => 'XSPEC TABLE MODEL',
            'model spectra for XSPEC'
        ],
        [ STRING => HDUVERS1 => '1.0.0', 'version of format' ] );

    # -------------------------------------
    # create PARAMETERS HDU

    @fields = (
        { type => 'NAME',     form => '12A', unit => ' ' },
        { type => 'METHOD',   form => 'J',   unit => ' ' },
        { type => 'INITIAL',  form => 'E',   unit => ' ' },
        { type => 'DELTA',    form => 'E',   unit => ' ' },
        { type => 'MINIMUM',  form => 'E',   unit => ' ' },
        { type => 'BOTTOM',   form => 'E',   unit => ' ' },
        { type => 'TOP',      form => 'E',   unit => ' ' },
        { type => 'MAXIMUM',  form => 'E',   unit => ' ' },
        { type => 'NUMBVALS', form => 'J',   unit => ' ' },
        { type => 'VALUE',    form => 'E',   unit => ' ' },
    );
    my %field = ();
    for my $col ( 1 .. @fields )
    {
        my $f = $fields[ $col - 1 ];
        $f->{col} = $col;
        $field{ $f->{type} } = $f;
    }

    my @ipars = _validate_pars( \%field, $opt{ipars}, 'interpolated' );
    my @apars = _validate_pars( \%field, $opt{apars}, 'additional' );

    # update form for VALUE to equal maximum NUMBVALS
    my $nvals = max map { scalar @{ $_->{VALUE} } } @ipars;
    $field{VALUE}{form} = $nvals . $field{VALUE}{form};

    _create_tbl( $fits, 'PARAMETERS', @fields );

    _write_cards(
        $fits,
        [],
        [ STRING => HDUCLASS => 'OGIP', 'format conforms to OGIP standard' ],
        [
            STRING =>
              HDUCLAS1 => 'XSPEC TABLE MODEL',
            'model spectra for XSPEC'
        ],
        [
            STRING =>
              HDUCLAS2 => 'PARAMETERS',
            'extension containing parameter info'
        ],
        [ STRING => HDUVERS1 => '1.0.0', 'version of format' ],
        [
            INT =>
              NINTPARM => scalar @ipars,
            'Number of interpolation parameters'
        ],
        [ INT => NADDPARM => scalar @apars, 'Number of additional parameters' ],
    );

    # -------------------------------------
    # write the parameters

    my $row = 0;
    for my $par ( @ipars, @apars )
    {
        $row++;

        while ( my ( $key, $value ) = each %{$par} )
        {
            my $field = $field{$key};

            if ( $field->{type} eq 'VALUE' )
            {
                my $numbvals = @$value;
                $fits->write_col_dbl( $field->{col}, $row, 1, $numbvals, $value,
                    $err );
                $fits->write_col_dbl( $field{NUMBVALS}{col},
                    $row, 1, 1, $numbvals, $err );
            }
            else
            {
                my $datatype = $field->{form} =~ /A/ ? TSTRING : TDOUBLE;
                $fits->write_col( $datatype, $field->{col}, $row, 1, 1, $value, $err );
            }
        }
    }

    # -------------------------------------
    # create the ENERGIES HDU

    @fields = (
        { type => 'ENERG_LO', form => 'E', unit => ' ' },
        { type => 'ENERG_HI', form => 'E', unit => ' ' },
    );

    _create_tbl( $fits, 'ENERGIES', @fields );

    _write_cards(
        $fits,
        [],
        [ STRING => HDUCLASS => 'OGIP', 'format conforms to OGIP standard' ],
        [
            STRING =>
              HDUCLAS1 => 'XSPEC TABLE MODEL',
            'model spectra for XSPEC'
        ],
        [
            STRING =>
              HDUCLAS2 => 'ENERGIES',
            'extension containing energy bin info'
        ],
        [ STRING => HDUVERS1 => '1.0.0', 'version of format' ],
    );

    # ick.
    my @energy  = @{ $opt{energy} };
    my $nenergy = @energy - 1;
    $fits->write_col_dbl( 1, 1, 1, $nenergy, \@energy, $err );
    shift @energy;
    $fits->write_col_dbl( 2, 1, 1, $nenergy, \@energy, $err );

    # -------------------------------------
    # finally, create the SPECTRA HDU

    @fields = (
        { type => 'PARAMVAL', form => @ipars . 'E',   unit => ' ' },
        { type => 'INTPSPEC', form => $nenergy . 'E', unit => $opt{units} },
    );

    push @fields,
      { type => "ADDSP$_", form => $nenergy . 'E', unit => $opt{units} }
      for 1 .. @apars;

    _create_tbl( $fits, 'SPECTRA', @fields );

    _write_cards(
        $fits,
        [],
        [ STRING => HDUCLASS => 'OGIP', 'format conforms to OGIP standard' ],
        [
            STRING =>
              HDUCLAS1 => 'XSPEC TABLE MODEL',
            'model spectra for XSPEC'
        ],
        [
            STRING =>
              HDUCLAS2 => 'ENERGIES',
            'extension containing energy bin info'
        ],
        [ STRING => HDUVERS1 => '1.0.0', 'version of format' ],
    );

    return $fits;
}

# --------------------------------
sub _create_tbl {

    my ( $fits, $extname, @fields ) = @_;

    tie my $err, 'Astro::FITS::CFITSIO::CheckStatus';

    $fits->create_tbl( BINARY_TBL,
        0,
        scalar @fields,
        [ map { $_->{type} } @fields ],
        [ map { $_->{form} } @fields ],
        [ map { $_->{unit} } @fields ],
        $extname,
        $err = "Error creating $extname HDU: "
    );

    return;
}

# --------------------------------
#  write FITS cards to the CHU.
#  Each card is an array with elements [ type, keyword, value, comment ]
#  where type is a string recognized by Astro::FITS::Header.

sub _write_cards {
    my ( $fptr, $items, @cards ) = @_;

    my $hdr = Astro::FITS::Header::CFITSIO->new( fitsID => $fptr );

    $hdr->insert( -1, $_ ) foreach @$items;

    $hdr->insert(
        -1,
        Astro::FITS::Header::Item->new(
            Type    => $_->[0],
            Keyword => $_->[1],
            Value   => $_->[2],
            Comment => $_->[3] ) ) foreach @cards;
    $hdr->writehdr( fitsID => $fptr );

    return;
}

# --------------------------------
#  validate parameter structures
sub _validate_pars {

    my ( $fields, $pars, $type ) = @_;

    # rewrite parameter hash with normalized keywords
    my @pars;

    my %keys = map { $_ => 1 } keys %{$fields};

    # exclude NUMBVALS,  as that's generated automatically
    my @delkeys = qw( NUMBVALS );

    # "additional" parameters don't need this
    push @delkeys, qw( METHOD VALUE )
      if $type eq 'additional';

    delete @keys{@delkeys};
    my @keys = keys %keys;

    my $row = 0;
    for my $par (@$pars)
    {
        $row++;

        # normalize keywords
        my %pars = map { uc $_ => $par->{$_} } keys %$par;

        my $name = $pars{NAME} || $row;

        # any missing?
        my @missing = grep { !defined $pars{$_} } @keys;
        croak( "$type parameter $name: missing attributes: ",
            join( ', ', @missing ), "\n" )
          if @missing;

        # any extra?  really meant to catch errors in "additional" parameters
        my @extra = grep { defined $pars{$_} } @delkeys;
        croak( "$type parameter $name: illegal extra attributes: ",
            join( ', ', @extra ), "\n" )
          if @extra;

        push @pars, \%pars;
    }

    return @pars;
}

1;

__END__

=head1 NAME

Astro::XSPEC::TableModel - Create XSPEC FITS Table Models


=head1 SYNOPSIS

    use Astro::XSPEC::TableModel qw( write_table );

    @ipars = ( \%ipar1, \%ipar2 );
    @apars = ( \%apar1, \%apar2 );

    $fptr = 
      write_table( output => $output_file,
                   model  => $model_name,
                   units  => $model_units,
                   additive => 1,            # true or false
                   redshift => 0,            # true or false
                   ipars => \@ipars,
                   apars => \@apars,
                   energy => \@energy,
                   keywords => \@items );


=head1 DESCRIPTION

B<Astro::XSPEC::TableModel> helps create table models for the B<XSPEC>
X-Ray spectral fitting package.  For a thorough discussion fo
B<XSPEC> and table models, please see L</SEE ALSO>.

This module provides the B<write_table> function, which is similar in
purpose to the B<wftbmd.c> provided as part of the HEASOFT
distribution.  It creates all of the administrative structures in the
FITS file, and returns control to the calling program at the point
where the actual table data (spectra) are written to the output file.
The caller is required to close the output file.

In order to construct the table, B<write_table> requires information
about the "interpolation" and "additional" parameters, as well as the
energy bins for the tables.

=head2 Parameter Specification

An "interpolation" or "additional" parameter is specified via a hash.
"Interpolation" parameters require the following entries (key case
not significant):

=over

=item  C<Name>

The name of the parameter.  It is truncated to 12 characters.

=item  C<Method>

The interpolation method: 0 if linear, 1 if logarithmic

=item  C<Initial>

Initial value in the fit for the parameter

=item  C<Delta>

Parameter delta used in fit (if negative parameter is frozen)

=item  C<Minimum>

Hard lower limit for parameter value

=item  C<Bottom>

Soft lower limit for parameter value

=item  C<Top>

Soft upper limit for parameter value

=item  C<Maximum>

Hard upper limit for parameter value

=item  C<Value>

The tabulated parameter values, as an arrayref.

=back

"Additional" parameters require the same entries I<except> for C<Value> and
C<Method>.

=head2 Energy grid

B<XSPEC> requires that energy bins be contiguous (i.e., the upper
bound of a bin is the same as the lower bound of the next). Since
adjoining bins share a common boundary value, a single array suffices
to describe the bins.  If there are I<$n> bins, the array should have
I<$n+1> elements, with element I<$energy[0]> being the lower bound of
the first bin, elements I<@energy[1..$n-1]> doing dual duty as lower
and upper bound values and element I<@energy[$n]> being the upper
bound of the last bin.


=head2 Writing models

After B<write_table> returns, the application must finish writing the
table by writing the spectra to the file.  The C<SPECTRA> HDU is
structured such that each row in the table represents the evaluation
of the model for a given set of parameter values.  The first element
(or "cell" in FITS speak) should contain a vector with the parameter
values for that instance of the model. The next element(s) should
contain vector(s) for the "interpolation" parameters' spectra, and the
final elements(s) (if any) should contain vectors for the "additional"
parameters' spectra.  As an example, consider a model with two
parameters, both interpolated, which has been evaluated on a 3x3 grid
of parameter values:

  X\Y 0 1 2
  0   . . .
  1   . . .
  2   . . .

There will be nine rows in the table.  The first row will
have a parameter value vector of C<[0,0]>, the next C[0,1], etc.
Assuming the function B<model($x, $y, \@energy)> returns an array
containing the model evaluated at C<@energy - 1> energies (see above
for the definition of the energy grid), then the application
could fill the table with the following code:

  my $row = 0;
  my $npars = 2;
  my $nbins = @energy - 1;
  for my $x ( 0, 1, 2 )
  {
      for my $y ( 0, 1, 2 )
      {
        $row++;
        my @spectrum = model( $x, $y, \@energy );
        my @pars = ( $x, $y );
        $fits->write_col_dbl( 1, $row, 1, $npars, \@pars, $status );
        $fits->write_col_dbl( 2, $row, 1, $nbins, \@spectrum, $status );
      }
  }

(In real code, check C<$status>. Use Astro::FITS::CFITSIO::CheckStatus
to do it automatically).  "Additional" parameter spectra would be
written directly after the "interpolated" parameters.

The spectra should be ordered with the last parameter changing most quickly.


=head1 INTERFACE

B<Astro::XSPEC::TableModel> provides a single exportable function

=over

=item write_table

    $fits = write_table( output => $output, ... );

B<write_table> creates a FITS table, initializing the structures
required for an B<XSPEC> table model.  It returns a reference to an
B<Astro::FITS::CFITSIO> file pointer, with the C<SPECTRA> HDU as the
current header unit.  The calling application should use that to
write the individual spectra into the FITS file, then should close
the file.

B<write_table> takes the following mandatory, I<named> arguments

=over

=item C<outfile>

The name of the file to which to write the FITS table.  If it exists
it will be overwritten.

=item C<model>

The name of the model. It will be truncated to 12 characters.

=item C<units>

The model units.  It will be truncated to 12 characters.

=item C<ipars>

A reference to an array of interpolation parameter specification
hashes, as described in L</Parameter Specification>.

=item C<energy>

A reference to a hash containing the energy bins.
energy => { type => ARRAYREF },

=back

The following I<named> arguments are optional:

=over

=item C<additive>

If true, the model is additive.  It defaults to false, or
multiplicative.

=item C<redshift>

If true, the B<XSPEC> should include a redshift parameter.  It defaults
to false.

=item C<apars>

A reference to an array of "additional" parameter specification hashes,
as described in L</Parameter Specification>.

=item C<keywords>

A reference to an array of B<Astro::FITS::Header::Item> objects, which
will be written to the primary HDU.

=back


=back

=head1 EXAMPLES

A simple example with one integration parameter.

  use Astro::XSPEC::TableModel;
  use Astro::FITS::CFITSIO::CheckStatus;

  # energy grid
  my @energy = ( 0..1024 );

  # interpolation parameters
  my @ipars = ( {
                 name => 'overlayer',
                 method => 0,
                 initial => 0,
                 delta => 1,
                 minimum => 0,
                 bottom => 0,
                 top => 10,
                 maximum => 10,
                 value => [ 0..10 ],
                }
              );

  # create the table
  my $fptr =
    write_table( output => 'table.fits',
                 model  => 'test',
                 units  => 'pints_of_ale/hr',
                 ipars  => \@ipars,
                 energy => \@energy,
               );

  # Fake some spectra.

  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

  my $row = 0;
  my $npars = 1;
  my $nbins = @energy - 1;
  for my $ol ( 0..10 )
  {
      $row++;
      my @spectrum = map {  1 + $ol**2 * $_ } @energy;
      $fptr->write_col_dbl( 1, $row, 1, $npars, [ $ol ], $status );
      $fptr->write_col_dbl( 2, $row, 1, $nbins, \@spectrum, $status );
  }

  $fptr->close_file( $status )


=head1 DIAGNOSTICS

Astro::XSPEC::TableModel will B<croak> upon error.

=over

=item C<< %s parameter %s: missing attributes: %s >>

The parameter specification is incomplete and is missing the listed attributes.

=item C<< %s parameter %s: illegal extra attributes: %s >>

The parameter specification has extra, unrecognized attributes.

=item C<< Error creating %s: %s >>

CFITSIO was unable to create the file for the given reason.

=item C<< Error creating %s HDU: %s >>

CFITSIO was unable to create the specified HDU for the given reason.

=back

Some error messages will be returned directly from the CFITSIO FITS library;
see its documentation for their meaning.

=head1 CONFIGURATION AND ENVIRONMENT

Astro::XSPEC::TableModel requires no configuration files or
environment variables.


=head1 DEPENDENCIES

List::Util,
Params::Validate,
Astro::FITS::CFITSIO,
Astro::FITS::CFITSIO::CheckStatus,
Astro::FITS::Header.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-astro-xspec-tablemodel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-XSPEC-TableModel>.

=head1 SEE ALSO

B<XSPEC> is documented at L<http://heasarc.nasa.gov/docs/xanadu/xspec/>.

The B<XSPEC> Table Model is documented at L<ftp://legacy.gsfc.nasa.gov/caldb/docs/memos/ogip_92_009/>.

=head1 ACKNOWLEDGEMENTS

The code in F<wftbmd.c> (shipped with XSPEC) was invaluable.

=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 The Smithsonian Astrophysical Observatory

Astro::XSPEC::TableModel is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>

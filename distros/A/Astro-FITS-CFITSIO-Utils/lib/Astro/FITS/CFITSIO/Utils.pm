# --8<--8<--8<--8<--
#
# Copyright (C) 2008 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::FITS::CFITSIO::Utils
#
# Astro::FITS::CFITSIO::Utils is free software: you can redistribute
# it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either version
# 3 of the License, or (at your option) any later version.
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

package Astro::FITS::CFITSIO::Utils;

use 5.006;
use strict;
use warnings;

use Carp;

our $VERSION = '0.13';

use Carp;

use Astro::FITS::Header::Item;

{
  package Astro::FITS::CFITSIO::Utils::Item;

  our @ISA = qw( Astro::FITS::Header::Item );

  sub new
  {
    my $class = shift;
    $class = ref $class || $class;

    my ($keyw, $value );
    # clean up input list, removing things that the superclass won't
    # understand. must be a better way to do this.
    my %args;
    my @o_args = @_;
    my @args;

    while(  ($keyw, $value ) = splice(@o_args, 0, 2 ) )
    {
      if ( $keyw =~ /^(?:hdu_num|)$/i )
      {
	$args{lc $keyw} = $value;
      }
      else
      {
	push @args, $keyw, $value;
      }
    }

    my $self = $class->SUPER::new( @args );

    # handle the attributes that we know about
    $self->$keyw( $value )
      while( ( $keyw, $value ) = each %args );

    return $self;
  }

  sub hdu_num
  {
    my $self = shift;
    if (@_) {
      $self->{hdu_num} = uc(shift);
    }
    return $self->{hdu_num};
  }
}

use Astro::FITS::Header::CFITSIO;
use Astro::FITS::CFITSIO
  qw[ READONLY CASEINSEN
      ANY_HDU ASCII_TBL BINARY_TBL
      BAD_HDU_NUM END_OF_FILE
   ];
use Astro::FITS::CFITSIO::CheckStatus;
use Params::Validate qw( validate_with :types );

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
keypar
keyval
colkeys
croak_status
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


# Preloaded methods go here.

# this is just a convenience wrapper around keypar
sub keyval
{
  my $opts = (@_ && 'HASH' eq ref $_[-1]) ? pop @_ : undef;

  keypar( @_, { defined $opts ? %$opts : () , Value => 1 } );
}



#  $k1 = keypar( $file, $kw1 );
#   implicit OnePerHDU = 1, Accumulate = 0
#   $k1 = first matching card

#  @k =  keypar( $file, $kw1 );
#   implicit OnePerHDU = 0, Accumulate = 1
#   @k = all matching cards

# ( $k1, $k2 ) = keypar( $file, [ $kw1, $kw2 ] );
#   implicit OnePerHDU = 1, Accumulate = 0
#   $k1 = first matching card
#   $k2 = first matching card

# $k = keypar( $file, [$kw1, $kw2] )
#   illegal



sub keypar
{
  my $file = shift;
  my $opts = (@_ && 'HASH' eq ref $_[-1]) ? pop @_ : undef;

  @_ == 1
    or croak( __PACKAGE__, "::keypar: incorrect number of arguments\n" );

  # set up defaults. they change to make things DWIM
  my %opt = ( Accumulate => ref $_[0] || ! wantarray() ? 0 : 1,
	      OnePerHDU  => ref $_[0] || ! wantarray() ? 1 : 0,
	      Value => 0,
	       $opts ? %$opts : ()
	     );

  $opt{CurrentHDU} = 0
    unless defined $opt{CurrentHDU} || $file =~ /\[/;

  my $keyword;

  if ( 'ARRAY' eq ref $_[0] )
  {
    $keyword = [ map { uc($_) } @{$_[0]} ];
  }

  elsif ( ! ref $keyword )
  {
    # don't do more work than the caller requests
    unless ( wantarray() )
    {
      $opt{Accumulate} = 0;
      $opt{OnePerHDU} = 1;
    }
    $keyword = [ uc $_[0] ];
  }
  else
  {
    croak( __PACKAGE__, "::keypar: illegal type for keyword\n" );
  }


  my %keywords = map { $_ => [] } @$keyword;

  # are we passed a pointer to an open file?
  my $file_is_open = eval { $file->isa( 'fitsfilePtr' ) };
  my $fptr;

  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

  if ( $file_is_open )
  {
      $fptr = $file;
  }

  else
  {
      $fptr = Astro::FITS::CFITSIO::open_file
	( $file, READONLY,
	  $status = __PACKAGE__ . "::keypar: error reading $file: " );
  }

  $fptr->get_hdu_num( my $init_hdu_num );
  $fptr->movabs_hdu( 1, undef, $status );
  $fptr->get_hdu_num( my $ext );

  # number of keywords found. used to short circuit search if
  # Accumulate == 0
  my $nfound = 0;

  for ( ;; $ext++ )
  {
    my $hdr = Astro::FITS::Header::CFITSIO->new( fitsID => $fptr,
						 ReadOnly => 1 );

    # loop over keywords
    while( my ( $keyw, $found ) = each %keywords )
    {
      # ignore this keyword if we've found a match and Accumulate
      # hasn't been set.
      next if @$found && ! $opt{Accumulate};

      my @newfound = $hdr->itembyname( $keyw );
      if ( @newfound )
      {
	$#newfound = 0 if $opt{OnePerHDU};
	foreach ( @newfound )
	{
	  my $item = Astro::FITS::CFITSIO::Utils::Item->new( Card => $_->card, HDU_NUM => $ext);
	  push @$found,
	    $opt{Value} && defined $item ? $item->value : $item;
	}
	$nfound ++;
      }
    }

    last if $opt{CurrentHDU} ||
      ! $opt{Accumulate} && $nfound == @$keyword;

    $fptr->movrel_hdu( 1, undef, my $lstatus = 0);

    last if $lstatus == BAD_HDU_NUM || $lstatus == END_OF_FILE;
    croak_status( $lstatus );
  }

  # done mucking about in the file; if it was an existing opened file
  # return to the initial HDU
  $fptr->movabs_hdu( $init_hdu_num, my $dummy, $status )
    if $file_is_open;

  # if passed an array ref for $keyword, prepare to handle multiple
  # keywords
  if ( ref $_[0] )
  {
    my @found;

    # a single value per keyword.  return list of scalars
    if ( $opt{OnePerHDU} && !$opt{Accumulate} )
    {
      @found = map { @{$_}[0] } @keywords{@$keyword};
    }

    # multiple values per keyword.  return list of arrayrefs.
    else
    {
      @found = @keywords{@$keyword};
    }
    return wantarray ? @found : \@found ;
  }

  else
  {
    my $found = $keywords{@{$keyword}[0]};

    return wantarray ? @$found : @$found ? @{$found}[0] : undef;
  }

  # NOT REACHED

}

sub colkeys {

    my $file = shift;

    my %opt = validate_with ( params => \@_,
                              spec => {
                                       extname => { type => SCALAR,
                                                    optional => 1 },
                                       extver  => { type => SCALAR,
                                                    regex => qr/^\d+$/,
                                                    optional => 1,
                                                    depends => [ 'extname' ]
                                                  }
                                      },
                              normalize_keys => sub { lc $_[0] },
                            );

    # are we passed a pointer to an open file?
    my $file_is_open = eval { $file->isa( 'fitsfilePtr' ) };
    my $fptr;
    my $init_hdu_num;

    tie my $error, 'Astro::FITS::CFITSIO::CheckStatus';

    if ( $file_is_open )
    {
	$fptr = $file;
	$fptr->get_hdu_num( $init_hdu_num );
    }
    else
    {
	$error = "Error reading $file: ";
	$fptr = Astro::FITS::CFITSIO::open_file( $file, READONLY, $error );
    }

    # move to specified HDU
    if ( $opt{extname} )
    {
        $opt{extver} ||= 0;
        my $extname = $opt{extname} . ($opt{extver} ? $opt{extver} : '');

        $error = "$file does not contain an extension of $extname";
        $fptr->movnam_hdu( ANY_HDU, $opt{extname}, $opt{extver}, $error );

        $fptr->get_hdu_type( my $hdutype, $error );

        croak( "$file\[$extname] is not a table\n")
          if $hdutype != ASCII_TBL and $hdutype != BINARY_TBL;
    }

    # find the first Table HDU
    else
    {
        my $status;

        while( 1 )
        {
            $error = "$file has no table extension";
            $fptr->movrel_hdu( 1, my $hdutype, $error );
            last if $hdutype == ASCII_TBL || $hdutype == BINARY_TBL;
        }
    }

    my $hdr = new Astro::FITS::Header::CFITSIO( fitsID => $fptr );

    $fptr->get_num_cols( my $ncols, $error );

    my %colkeys;
    for my $coln (1..$ncols) {

        my %info;

        $fptr->get_colname( CASEINSEN, $coln, my $oname, undef, $error );
        my $name = lc $oname;

        # blank name!  can't have that.  just # number 'em after the
        # actual column position.
        $name = "col_$coln" if  '' eq $name;

        if ( exists $colkeys{$name} )
        {
            my $idx = 1;

            $idx++ while exists $colkeys{ "${name}_${idx}" };
            $name = "${name}_${idx}";
        }

        for my $item ( grep { $_ !~ /^NAXIS/ }
		       $hdr->itembyname( qr/\D+$coln([a-z])?$/i ) )
        {
            my $key = lc join('',
			      grep { defined }
			      $item->keyword =~ /(.*)$coln(.*)$/ );
            $info{$key} = $item->value;
        }

        $colkeys{$name} = { hdr => \%info,
                           idx => $coln };
    }

    # done mucking about in the file; if it was an existing opened file
    # return to the initial HDU
    $fptr->movabs_hdu( $init_hdu_num, undef, $error )
      if $file_is_open;

    return %colkeys;
}

sub croak_status {
  my $s = shift;

  if ($s)
  {
    Astro::FITS::CFITSIO::fits_get_errstatus($s, my $txt);

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    croak @_, "CFITSIO Error: $txt\n";
  }
}



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Astro::FITS::CFITSIO::Utils - FITS utility routines

=head1 SYNOPSIS

  use Astro::FITS::CFITSIO::Utils;


=head1 DESCRIPTION

This is a bundle of useful FITS routines which use CFITSIO.

=head2 Errors

Errors are generally returned by B<croak()>ing.  Error messages
will begin with C<Astro::FITS::CFITSIO::Utils>.


=head1 Functions

=over 8

=item keyval

This is a wrapper around B<keypar> which sets the C<Value> option.
For example, instead of this kludge:

  $value = keypar( $file, $keyword, { Value => 1 } );

you can type

  $value = keyval( $file, $keyword );

Everything else is the same as B<keypar> (including the error messages,
which refer to B<keypar>).

=item keypar

  # single keyword, return first match
  $myitem  = keypar( $file, $keyword, [\%opts] );

  # single keyword, multiple HDU matches
  @myitems = keypar( $file, $keyword, [\%opts] );


  # multiple keywords
  @items = keypar( $file, \@keyw, [\%opts] );

This routine searches the headers in the specified FITS file for a
keyword with the given name.  C<$file> may be a filename or a file heandle
returned by B<Astro::FITS::CFITSIO::open_file()>.  In the latter case
the handle's current HDU is restored after the call to B<keypar>.

The matching keywords are returned either as
B<Astro::FITS::CFITSIO::Utils::Item> objects which inherit from
B<Astro::FITS::Header::Item> objects, as the value of the keyword (if
the C<Value> option is specified), or B<undef> if no match was found.
The B<myItem> object adds a member B<hdu_num> which records the number
of the HDU in which the keyword is found.

A single keyword may be matched multiple times in an HDU (if it is
either C<COMMENT> or C<HEADER>) as well as in multiple HDU's.
This behavior is regulated with the C<Accumulate> and C<OnePerHDU>
option flags, which are passed via the optional hashref argument (C<\%opts>).

If C<Accumulate> is set, all of the HDU's are scanned for the
keyword(s).  If C<OnePerHDU> is set, only the first match in an HDU is
returned.

The default values for these options depends upon the context in
which B<keypar> is called. B<keypar> attempts to provide the most
intuitive behavior.

=over 8

=item *

If a single keyword is passed (as a scalar) and B<keypar> is called in
a scalar context, the first match is returned.

=item *

If a single keyword is passed (as a scalar) and B<keypar> is called in
a list context, C<Accumulate> defaults to 1 and C<OnePerHDU> to 0.
This means that all possible matches will be returned.  Recall that
C<OnePerHDU> only affects C<COMMENT> and C<HEADER> keywords.

=item *

If an arrayref of keyword(s) is passed C<Accumulate> defaults to 0 and
C<OnePerHDU> to 1.  This results in the following behavior:

  ( $hdr_keyw1, $hdr_keyw2 ) =
          keypar( $file, [ $keyw1, $key2 ] );

If either C<OnePerHDU> = 0 or C<Accumulate> = 1, a keyword might
match multiple times, and the returned values are arrayrefs containing
the list of matched items:

  ( $arrayref_keyw1, $arrayref_keyw2 ) =
         keypar( $file, [ $keyw, $keyw2],
                  { Accumulate => 1 } );

=back

The available option flags are:

=over 8

=item Accumulate

If set, matching keywords from all HDU's are returned, not just from
the first HDU which has one.  This defaults to C<0> (off).

=item CurrentHDU

Scan only the current HDU.  This defaults to C<1> (on) if the filename
contains extension information, C<0> (off) otherwise.  B<keypar> uses
a crude method of determining if extension information is present (it
checks for the C<[> character in the filename ), so it may be confused
if a filter expression is part of the filename.

=item OnePerHDU

If set, only one match will be made per HDU. This affects only the
C<COMMENT> and C<HEADER> keywords.

=item Value

If non-zero, returns the I<value> of the keyword, rather than a reference
to the keyword object.

=back

=item colkeys

   %colkey = colkeys( $filename, [\%opts] );

Retrieve the keywords associated with columns in a table in the given
FITS file.  If no HDU is specified in the options, it will use
the first table HDU found.

The following options are recognized:

=over

=item extname

The name of the extension from which to retrieve the keywords.

=item extver

The version of the extension from which to retrieve the keywords.
Ignored if C<extname> is not also specified.  If not specified,
the first extension with a matchine C<extname> is used.

=back

The keys in the returned hash are the lowercased column names.  The
values are hashrefs, with the following values:

=over

=item idx

The unary based index of the column in the extension

=item hdr

A hashref.  The hash keys are the lower-cased names of the keywords
for the given column, with the trailing column index removed.  The
hash values are the keyword values.

=back


=item croak_status

        croak_status($status, @msg );

B<Deprecated>: use the B<Astro::FITS::CFITSIO::CheckStatus> module
instead.

Checks the CFITSIO status variable. If it indicates an error,
it B<croak()>'s, outputting first the passed message, then the
the corresponding CFITSIO error message. A newline character C<\n>
will be appended to the message.

The carp level is adjusted to make the croak appear to be called from
the calling routine.

=back

=head2 EXPORT

None by default.

=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-astro-fits-cfitsio-utils@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-FITS-CFITSIO-Utils>.

=head1 SEE ALSO

L<Astro::FITS::CFITSIO>, L<perl>.

=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 The Smithsonian Astrophysical Observatory

Astro::FITS::CFITSIO::Utils is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>

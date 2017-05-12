package Astro::FITS::CFITSIO::Simple;

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

# This allows declaration	use Astro::FITS::CFITSIO::Table ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
  rdfits
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.18';

# cheap and dirty clean up object so that we can maintain
# return contexts in rdfits and its delegates by having
# cleanup done during object destruction
{
  package Astro::FITS::CFITSIO::Simple::Cleanup;

  sub new { my $class = shift; bless {@_}, $class };
  sub set { $_[0]->{$_[1]} = $_[2] };
  sub DESTROY{ my $s = shift;
	       tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';
	       $s->{fptr}->perlyunpacking($s->{packing})
		 if defined $s->{packing};
	       $s->{fptr}->movabs_hdu( $s->{hdunum}, undef, $status)
		 if defined $s->{hdunum} }
}



# HDU types we recognize
our %HDUType = (
		img    => IMAGE_HDU,
		image  => IMAGE_HDU,
		binary => BINARY_TBL,
		bintbl => BINARY_TBL,
		ascii  => ASCII_TBL,
		any    => ANY_HDU,
		table  => undef, 	# the CFITSIO flags aren't really bits
	       );

sub validHDUTYPE { exists $HDUType{lc $_[0]} }
sub validHDUNUM  { $_[0] =~ /^\d+$/ && $_[0] > 0 }



# these are the Params::Validate specifications for rdfits
# they are specified separately here, so that parameters
# for _rdfitsTable and _rdfitsImage can be split out
# from the main option hash

our %rdfits_spec = 
  (
   extname  => { type => SCALAR,  optional => 1 },
   extver   => { type => SCALAR,
		 depends => 'extname',
		 default  => 0 },
   hdunum   => { type => SCALAR,
		 callbacks => { 'illegal HDUNUM' =>
				\&validHDUNUM,
			      },
		 optional => 1 },
   hdutype  => { type => SCALAR,
		 callbacks => { 'illegal HDU type' =>
				\&validHDUTYPE,
			      },
		 default => 'any',
		 optional => 1 },
   resethdu => { type => SCALAR,  default  => 0 },
  );

sub rdfits
{

  # strip off the options hash
  my $opts = 'HASH' eq ref $_[-1] ? pop : {};

  # first arg is fitsfilePtr or filename
  my $input = shift;

  croak( "input must be a fitsfilePtr or a file name\n" )
    unless defined $input && 
      ( UNIVERSAL::isa( $input, 'fitsfilePtr' ) || ! ref $input );


  # rdfits is a dispatch routine; we need to filter out the options
  # for the delegates (and vice versa).  final argument validation
  # is done by the the delegates

  # shallow copy, then delete non-rdfits options.
  my %rdfits_opts = %{$opts};
  delete @rdfits_opts{ grep { !exists $rdfits_spec{ lc($_) } }
			 keys %rdfits_opts };

  # shallow copy, then delete rdfits options
  my %delegate_opts = %{$opts};
  delete @delegate_opts{ keys %rdfits_opts };

  # if there are additional arguments, guess that we're being
  # asked for some columns, and set the requested HDUTYPE to table
  $rdfits_opts{hdutype} = 'table' if @_;

  # validate arguments
  my %opt =
    validate_with( params => [ \%rdfits_opts ],
		   normalize_keys => sub{ lc $_[0] },
		   spec => \%rdfits_spec );



  # CFITSIO file pointer
  my $fptr;

  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

  my $cleanup;

  # get CFITSIO file pointer
  if (UNIVERSAL::isa( $input, 'fitsfilePtr')) 
  {

    $fptr = $input;

    $cleanup = new Astro::FITS::CFITSIO::Simple::Cleanup 
      ( fptr => $fptr, packing => $fptr->perlyunpacking );

    if ( $opt{resethdu} )
    {
      $fptr->get_hdu_num( my $hdunum );
      $cleanup->set( hdunum => $hdunum );
    }

  }
  else
  {
    $fptr = Astro::FITS::CFITSIO::open_file($input, READONLY,
			    $status = "could not open FITS file '$input'");
  }

  # we're not unpacking; 
  $fptr->perlyunpacking(0);

  # read in all of the extensions
  if ( $opt{slurp} )
  {
    croak( "slurp not yet implemented!\n" );
  }

  # read in just one
  else
  {
    my $hdutype;

    # HDU specified by name
    if ( exists $opt{extname} )
    {
      $fptr->movnam_hdu(ANY_HDU, $opt{extname}, $opt{extver},
	$status = "could not move to HDU '$opt{extname}:$opt{extver}'");

      $fptr->get_hdu_type( $hdutype, $status );

      croak( "requested extension does not match requested HDU type\n" )
	unless match_hdutype( $opt{hdutype}, $hdutype );
    }

    # HDU specified by number?
    elsif ( exists $opt{hdunum} )
    {
      $fptr->movabs_hdu( $opt{hdunum}, $hdutype, $status );

      croak( "requested extension does not match requested HDU type\n" )
	unless match_hdutype( $opt{hdutype}, $hdutype );
    }

    # first recognizeable one
    else
    {
      # lazy; let CheckStatus do the work.
      eval {
	until ( $status )
	{
	  $fptr->get_hdu_type($hdutype, $status);

	  # check that we're in an actual image, i.e. NAXIS != 0
	  if ( IMAGE_HDU == $hdutype )
	  {
	    $fptr->get_img_dim( my $naxis, $status );
	    next unless $naxis;
	  }
	  last if match_hdutype( $opt{hdutype}, $hdutype );

	}
	continue
	{
	  $fptr->movrel_hdu( 1, $hdutype, $status ); 
	}
      };

      # ran off end of file
      croak( "unable to find a matching HDU to read\n" )
	if BAD_HDU_NUM == $status;

      # all other errors
      croak $@ if $@;
    }

    # update args. $cleanup must be passed so that it will be destroyed
    # after the delegate routine has finished.
    unshift @_, $fptr, $cleanup;

    # add the options for the delegate
    push @_, \%delegate_opts;

    # dispatch. we use the dispatch goto here to keep croak's etc. at the
    # correct level and to maintain the calling context.
    BINARY_TBL == $hdutype || ASCII_TBL == $hdutype
      and goto &_rdfitsTable;

    IMAGE_HDU == $hdutype
      and goto &_rdfitsImage;

    croak( "internal error. bizarre hdutype = $hdutype\n" );
  }

  croak( "internal error; can't get here from there\n" );

}

# a thin front end for reading in a table

sub rdfitstbl
{
  # make shallow copy of passed options hash (or create one)
  my %opt = 'HASH' eq ref $_[-1] ? %{pop @_} : ();

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

sub rdfitsimg
{
  # make shallow copy of passed options hash (or create one)
  my %opt = 'HASH' eq ref $_[-1] ? %{pop @_} : ();

  # force the HDU to match a table
  $opt{hdutype} = 'image';

  # read only one HDU
  delete $opt{slurp};

  # attach our new options hash
  push @_, \%opt;

  # do the whole shebang; pretend we were never here.
  goto &rdfits;
}

sub match_hdutype
{
  my ( $req, $actual ) = @_;

  return (BINARY_TBL == $actual || ASCII_TBL  == $actual )
    if 'table' eq $req;

  my $reqtype = $HDUType{ $req };

  return 1 if ANY_HDU == $reqtype;

  return 1 if $reqtype == $actual;


  0;
}


1;

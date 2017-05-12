package Astro::FITS::CFITSIO::Simple::Table;

use 5.008002;
use strict;
use warnings;

require Exporter;

use Params::Validate qw/ :all /;

use Carp;

use POSIX ();
use Scalar::Util qw/blessed/;
use PDL;
use PDL::Core qw[ byte ushort long ];

use Astro::FITS::CFITSIO qw/ :constants /;
use Astro::FITS::CFITSIO::CheckStatus;
use Astro::FITS::CFITSIO::Simple::PDL qw/ :all /;
use Astro::FITS::Header;
use Astro::FITS::Header::CFITSIO;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  _rdfitsTable
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.18';

# this must be called ONLY from rdfits.  it makes assumptions about
# the validity of arguments that have been verified by rdfits.

sub _rdfitsTable
{

  my $opts = 'HASH' eq ref $_[-1] ? pop : {};

  # first arg is fitsfilePtr
  # second is cleanup object; must keep around until we're done,
  # so it'll cleanup at the correct time.
  my $fptr = shift;
  my $cleanup  = shift;

  croak( "column names must be scalars\n" ) if grep { ref $_ } @_;

  my @req_cols = map { lc $_ } @_;


  my %opt = 
    validate_with( params => [ $opts ],
		   normalize_keys => sub{ lc $_[0] },
		   spec =>
		 {
                  nullval  => { type => SCALAR,  optional => 1 },
		  rfilter  => { type => SCALAR,  optional => 1 },
		  dtypes   => { type => HASHREF, optional => 1 },
		  defdtype => { isa => qw[ PDL::Type ], optional => 1 },
		  ninc     => { type => SCALAR,  optional => 1 },
		  rethash  => { type => SCALAR,  default  => 0 },
		  retinfo  => { type => SCALAR,  default  => 0 },
		  rethdr   => { type => SCALAR,  default  => 0 },
		  status   => { callbacks =>
			        {
				  "boolean, filehandle, subroutine, or object" => \&validate_status
				},
				optional => 1 },
		 } );

  # data structure describing the columns
  my %cols;

  # final list of columns (not column names!)
  my @cols;

  # CFITSIO status variable
  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

  # normalize column names for user specified types.
  my %user_types = map { lc($_) => $opt{dtypes}{$_} } keys %{$opt{dtypes}};


  # see if we're to delete columns
  my @del_cols = map { s/-//; $_ } grep { /^-/ } @req_cols;

  # if columns are to be deleted, can't have any other things in the list
  die( "can't mix -col and col specifictions in list of columns\n" )
    if @del_cols && @del_cols != @req_cols;

  @req_cols = ()
  if @del_cols;

  my %del_cols = map { ( $_ => 1 ) } @del_cols;


  # hash of requested column names (if any); used to track
  # non-existant columns
  my %req_cols = map { ( $_ => 0 ) } @req_cols;

  # by default return a hash of data unless columns are requested
  # (del_cols don't count)
  $opt{rethash} = 1 unless @req_cols || $opt{retinfo};

  # grab header
  my $hdr = new Astro::FITS::Header::CFITSIO( fitsID => $fptr );

  # grab the number of columns and rows in the HDU
  $fptr->get_num_cols( my $ncols, $status );
  $fptr->get_num_rows( my $nrows, $status);

  # this is the number of rows to process at one time.
  my $ninc = $opt{ninc};
  $ninc or $fptr->get_rowsize($ninc, $status);
  $ninc = $nrows if $nrows < $ninc;

  # use transfer buffers until we can figure out how to read chunks
  # directly into the final piddles. These are indexed off of the
  # shape of the piddle so that we can reuse them and save memory.
  my %tmppdl;

  # create data structure describing the columns
  for my $coln (1..$ncols) {

    $fptr->get_colname( CASEINSEN, $coln, my $oname, undef, $status);
    my $name = lc $oname;

    # blank name!  can't have that.  unlike PDL::IO::FITS we just
    # number 'em after the actual column position.
    $name = "col_$coln" if  '' eq $name;

    # check for dups; can't have that either! Follow PDL::IO::FITS
    # convention
    if ( exists $cols{$name} )
    {
      my $idx = 1;

      $idx++ while exists $cols{ "${name}_${idx}" };
      $name = "${name}_${idx}";
    }

    # fix up header to track name change
    if ( $name ne lc $oname )
    {
      if ( defined ( my $item = $hdr->itembyname( "TTYPE$coln" ) ) )
      {
	$item->value( uc $name );
      }
      else
      {
	$hdr->insert( -1, new Astro::FITS::Header::Item
		      ( Keyword => "TTYPE$coln",
			Value   => uc $name,
			Comment => 'Label for field',
			Type    => 'string' ) );
      }
    }

    # we don't care about a column if it wasn't requested (if any
    # were requested)
    next if exists $del_cols{$name} || 
      ( @req_cols && ! exists $req_cols{ $name } );
    $req_cols{$name}++;

    # preset fields used as arguments to CFITSIO as that doesn't seem
    # to  auto-vivify them
    my $col = $cols{$name} =
       { map { $_ => undef } qw/ btype repeat width naxes btype / };

    $col->{n} = $coln;
    $col->{name} = $name;


    $fptr->get_eqcoltype( $coln, $col->{btype}, $col->{repeat},
			  $col->{width}, $status );

    # momentarily read into a Perl array, rather than a piddle
    $fptr->perlyunpacking(1);
    $fptr->read_tdim( $coln, my $naxis, $col->{naxes} = [], $status );
    $fptr->perlyunpacking(0);

    # figure out what sort of piddle to store the data in
    $col->{ptype} = undef;

    # user specified piddle type?
    if ( exists $user_types{$name} || exists $opt{defdtype} )
    {
      my $type = delete $user_types{$name} || $opt{defdtype};

      # bit columns are so special
      if ( TBIT == $col->{btype} )
      {
	# this results in one piddle byte per bit
	if ( $type =~ /logical/ )
	{
	  $col->{ptype} = byte;
	  $col->{ctype} = TBIT;
	}
	elsif ( ! UNIVERSAL::isa( $type, 'PDL::Type' ) )
	{
	  croak( "unrecognized user specified type for column '$name'" );
	}
	elsif ( $type != byte && $type != ushort && $type != long )
	{
	  croak( "bit column type must be byte, ushort, long, or the string 'logical'\n" );
	}
	else
	{
	  $col->{ptype} = $type;
	  $col->{ctype} = TBYTE;
	}
      }

      elsif ( ! UNIVERSAL::isa( $type, 'PDL::Type' ) )
      {
	croak( "unrecognized user specified type for column '$name'" );
      } elsif (   $col->{btype} == TLOGICAL
		  || $col->{btype} == TSTRING )
      {
	carp("ignoring user specified type for column '$name': either LOGICAL, STRING" );
      } else
      {
	$col->{ptype} = $type;
      }

    }

    # user didn't set it?  TBIT is still so special; all handling is done below
    if ( TBIT != $col->{btype} && ! defined $col->{ptype} )
    {
      eval {
	$col->{ptype} = fits2pdl_coltype( $col->{btype} );
      };
      croak( "column $col->{name}: $@\n" )
	if $@;
    }


    # create the storage area 

    # note that we have to match the PDL storage type to the closest
    # CFITSIO type, based primarily on size.

    # strings get read into Perl variables
    if ( TSTRING == $col->{btype} )
    {
      $col->{data} = [];

      # not meaningful
      $col->{ctype} = undef;
    }

    else
    {

      my $code = '';

      # if this is a bit column, and the user hasn't specified that
      # "logical" piddles be used, create a dense map
      if ( TBIT == $col->{btype} && 
	   ! ( defined $col->{ctype} && TBIT == $col->{ctype}) )
      {
	$code = map_bits( $col );
      }

      else
      {
	# simplify data layout if this is truly a 1D data set (else
	# PDL will create a ( 1 x N ) piddle, which is unexpected.
	# can't get rid of singleton dimensions if this is a n > 1 dim
	# data set
	$col->{naxes} = []
	  if @{$col->{naxes}} == 1 && 1 == $col->{naxes}[0];


	if ( $col->{btype} == TLOGICAL() )
	{
	  $col->{ctype} = TLOGICAL();
	}

	# ctype may have beend defined above; make sure we don't overwrite it.
	elsif ( ! defined $col->{ctype} )
	{
	  $col->{ctype} = pdl2cfitsio($col->{ptype});
	}

	# shape of temporary is same as shape of final
	$col->{tmpnaxes} = $col->{naxes};

	# same repeat count as final
	$col->{tmprepeat} = $col->{repeat};

	# set up formats for destination and source slices to copy
	# from temp to final destination 
	$col->{dst_slice} = ':,' x @{$col->{naxes}} . '%d:%d';
	$col->{src_slice} = ':,' x @{$col->{naxes}} . '0:%d';


	$code = q/ my ( $col, $start, $nrows ) = @_;
	  my $dest = sprintf($col->{dst_slice}, $start, 
			     $start + $nrows - 1);
	  my $src  = sprintf($col->{src_slice}, $nrows - 1);
	  (my $t = $col->{data}->slice($dest)) .= $col->{tmppdl}->slice($src);
                   /;
      }

      eval '$col->{dataxfer} = sub { ' . $code . '}';
      croak( "internal error in generating dataxfer code: $@\n" )
	if $@;

      # create final and temp piddles.
      $col->{data} =
	$nrows
	  ? PDL->new_from_specification( $col->{ptype}, @{$col->{naxes}}, $nrows )
	  : PDL->null;

      # shape of temporary storage for this piddle.
      $col->{tmpshape} = join( ",", $col->{ptype},
			       @{$col->{tmpnaxes}}, $ninc );

      # reuse tmppdls
      $tmppdl{$col->{tmpshape}} =
	( $ninc 
	    ? PDL->new_from_specification( $col->{ptype}, @{$col->{tmpnaxes}}, $ninc )
	    : PDL->null )
	  unless defined $tmppdl{$col->{tmpshape}};

      $col->{tmppdl} = $tmppdl{$col->{tmpshape}};


      # How to handle null pixels.  A nullval of zero signals CFITSIO to
      # ignore null pixels
      $col->{nullval} = exists $opt{nullval}   ? $opt{nullval}
                      : $PDL::Bad::Status      ? badvalue( $col->{ptype} )
                      :                          0;
      $col->{anynul} = 0;
    }

    # grab extra column information if requested
    if ( $opt{retinfo} )
    {
      $col->{retinfo}{hdr} = {};

      for my $item ( $hdr->itembyname( qr/T\D+$col->{n}$/i ) )
      {
	$item->keyword =~ /(.*?)\d+$/;
	$col->{retinfo}{hdr}{lc $1} = $item->value;
      }

      $col->{retinfo}{idx}  = $col->{n};
    }

  }

  # now, complain about extra parameters
  {
    my @notfound = grep { ! $req_cols{$_} } keys %req_cols;
    croak( "requested column(s) not in file: ", join(", ", @notfound) )
      if @notfound;

    croak( "user specified type(s) for columns not in file: ", 
	 join(", ", keys %user_types ), "\n" )
      if keys %user_types;
  }

  # construct final list of columns to be read in, either from the
  # list the user provided, or from those in the file (sorted by
  # column number).
  @cols = @req_cols ?
    @cols{@req_cols} :
      sort { $a->{n} <=> $b->{n} } values %cols;


  # scalar context, more than one column returned? doesn't make sense,
  # does it?
  # test for this early, as it may be an expensive mistake...
  croak( "rdfitsTable called in scalar context, but it's to read more than one column?\n" ) 
    if ! wantarray() && @cols > 1;

  # create masks if we'll be row filtering
  my ($good_mask, $tmp_good_mask, $ngood);

  if ($nrows && $opt{rfilter}) {
    $good_mask = ones(byte,$nrows);
    $tmp_good_mask = ones(byte,$ninc);
    $ngood = 0;
  }

  # start status output
  # prepare for status updates
  my $progress;
  if ( defined $opt{status} )
  {
    require Astro::FITS::CFITSIO::Simple::PrintStatus;
    eval {
      $progress = Astro::FITS::CFITSIO::Simple::PrintStatus->new( $opt{status}, $nrows );
    };
    croak($@) if $@;
  }


  $progress->start( ) if $progress;

  my $next_update = 0;
  my $rows_done = 0;
  while ($rows_done < $nrows) {

  $next_update = $progress->update( $rows_done )
    if $progress && $rows_done >= $next_update;

    my $rows_this_time = $nrows - $rows_done;
    $rows_this_time = $ninc if $rows_this_time > $ninc;

    # row filter
    if ($opt{rfilter}) {
      my $tmp_ngood = 0;
      $fptr->find_rows( $opt{rfilter}, $rows_done+1, $rows_this_time, 
			$tmp_ngood,
			${$tmp_good_mask->get_dataref}, 
			$status = "error filtering rows: rfilter = '$opt{rfilter}'" );
      $tmp_good_mask->upd_data;

      (my $t = $good_mask->mslice( [$rows_done, 
				    $rows_done+$rows_this_time-1]) ) .=
	$tmp_good_mask->mslice( [0, $rows_this_time-1] );

      $ngood += $tmp_ngood;

      $tmp_ngood > 0 or
	$rows_done += $rows_this_time,
	  next;
    }

    for my $col ( @cols ) {

      # beware of empty repeat fields
      next unless $col->{repeat};

      if (TSTRING != $col->{btype} ) {

	$fptr->read_col( $col->{ctype},
			 $col->{n},
			 $rows_done+1, 1,
			 $col->{tmprepeat} * $rows_this_time,
			 $col->{nullval},
			 ${$col->{tmppdl}->get_dataref},
			 $col->{anynul},
			 $status = "error reading FITS data"
		       );

	$col->{tmppdl}->upd_data;

	# transfer the data to the final piddle
	$col->{dataxfer}->($col, $rows_done, $rows_this_time);
	$col->{data}->badflag($col->{anynul}) if $PDL::Bad::Status;

      } else {			# string type
	my $tmp = [];
	$fptr->read_col(TSTRING,
			$col->{n},
			$rows_done+1, 1,
			$rows_this_time,
			0,
			$tmp,
			undef,
			$status = "error reading FITS data",
		       );
	push @{$col->{data}}, @$tmp;
      }

    }
    $rows_done += $rows_this_time;

  }

  if ($nrows && $opt{rfilter}) {

    my $good_index = which($good_mask);

    for my $col ( @cols ) {

      # beware of empty repeat fields
      next unless $col->{repeat};

      if ( TSTRING != $col->{btype} ) {
	$col->{data} = $col->{data}->dice( ('X') x @{$col->{naxes}},
					   which( $good_mask ) );
      } else {			# string type
	@{$col->{data}} = @{$col->{data}}[$good_index->list];
      }
    }
  }


  # it's all done
  $progress->update( $nrows ) 
    if $progress && $nrows >= $next_update;

  $progress->finish()
    if $progress;

  # how shall i return the data? let me count the ways...
  if ( $opt{retinfo} )
  {
    # gotta put the data into the retinfo structure.
    # it's safer to do that here, as we have reassigned 
    # $col->{data} above.
    my %retvals;
    foreach ( @cols )
    {
      $_->{retinfo}{data} = $_->{data};
      $retvals{$_->{name}} = $_->{retinfo};
    }

    $retvals{_hdr} = $hdr if $opt{rethdr};
    return %retvals;
  }

  if ( $opt{rethash} )
  {
    my %retvals = map { $_->{name} => $_->{data} } @cols;
    $retvals{_hdr} = $hdr if $opt{rethdr};
    return %retvals;
  }

  # just return the data in the order they were requested.
  if ( wantarray() )
  {
    my @retvals = map { $_->{data} } @cols;
    unshift @retvals, $hdr if $opt{rethdr};
    return @retvals;
  }

  # if we're called in a scalar context, and there's but one column,
  # return the column directly.  always stick in the header, as a freebee
  if ( 1 == @cols )
  {
    my $pdl = $cols[0]->{data};
    tie my %hdr, 'Astro::FITS::Header', $hdr;
    $pdl->sethdr( \%hdr );
    return $pdl;
  }

  # scalar context, more than one column returned? doesn't make sense,
  # does it? we've tested for this before, but it doesn't hurt to stick
  # it here to remind us.

  croak( "rdfitsTable called in scalar context, but it read more than one column?\n" );

}

# map a BIT column onto the best fit pdl type.  this stores the
# bits as densely as possible.
sub map_bits
{
  my ( $col ) = @_;

  # we're not reading bit columns into boolean vectors (i.e. each
  # piddle element is one bit). we do a bit of soft shoe to first
  # read the bit columns as bytes into the temp array and then
  # bitwise or them into the final piddle

  # if the user hasn't specified the final piddle type the
  # special code paths above ensure that $col->{ptype} is still
  # undefined.  in this case we try to find the best sized PDL
  # type for the FITS element size, where the latter is the
  # first element in the tdim array (which will be the column
  # repeat value if TDIMn isn't given).

  # the number of bytes needed to hold the number of bits. round up.
  my $nbytes = POSIX::ceil($col->{naxes}[0] / 8 );

  unless ( defined $col->{ptype} ) {
    # fall back to using bytes
    $col->{ptype} = byte;

    # find the smallest PDL type that will hold an element of the data
    for my $type ( byte, ushort, long ) # no longlong yet
      {
	next unless PDL::Core::howbig($type->enum) == $nbytes;
	$col->{ptype} = $type;
	last;
      }
  }

  # the number of integral piddles required to hold a single element
  my $npiddle =
    POSIX::ceil($nbytes / PDL::Core::howbig($col->{ptype}->enum));

  # adjust to reflect the fact that the "repeat" count is no
  # longer in bits.
  $col->{naxes}[0] = $npiddle;
  shift @{$col->{naxes}} if $npiddle == 1;

  # simplify data layout if this is truly a 1D data set (else
  # PDL will create a ( 1 x N ) piddle, which is unexpected.
  # can't get rid of singleton dimensions if this is a n > 1 dim
  # data set
  $col->{naxes} = []
    if @{$col->{naxes}} == 1 && 1 == $col->{naxes}[0];

  # recalculate repeat value
  $col->{repeat} = 1;
  $col->{repeat} *= $_ foreach @{$col->{naxes}};

  # temp piddle type is same as final piddle, as we may have to
  # shift bits, and we don't want them to shift off of the
  # element
  $col->{ctype} = pdl2cfitsio($col->{ptype}) 
    unless defined $col->{ctype};

  # shape of temporary storage for this piddle. we rework
  # $col->{naxes} which now is in terms of $col->{ptype}, not in
  # bits. we want it in bytes, as that's the smallest chunk of
  # bits CFITSIO will give us
  my @naxes = (1, @{$col->{naxes}});
  $naxes[0] = PDL::Core::howbig( $col->{ptype}->enum );

  $col->{tmpnaxes} = \@naxes;

  # up the repeat count to handle the fact we're reading in bytes
  $col->{tmprepeat} = 1;
  $col->{tmprepeat} *= $_ foreach @naxes;

  # generate subroutine to copy from temp to final
  my $code = '';
  $code = q/ my ( $col, $start, $nrows ) = @_;
                   my $dst = $col->{data}->dummy(0);
		   my $src = $col->{tmppdl};
                /;

  my $dst = join( '',
		  '$dst->mslice([],',
		  '[],' x (@{$col->{naxes}}), 
		  '[$start,$start+$nrows-1])' );


  if ( $col->{tmpnaxes}[0] > 1 )
  {
    $code .= "$dst .= 0;\n";

    for my $pidx ( 0..$col->{tmpnaxes}[0]-1 ) {
      my $src =  join('',
		      '$src->mslice([', $pidx , '],',
		      '[],' x (@{$col->{tmpnaxes}}-1),
		      '[0,$nrows-1]) << ', 8*$pidx );

      $code .= "$dst |= $src;\n";
    }
  }
  else
  {
    my $src =  join('',
		    '$src->mslice([0],',
		    '[],' x (@{$col->{tmpnaxes}}-1),
		    '[0,$nrows-1])' );

    $code .= "$dst .= $src;\n";
  }

  $code;
}



# quick and dirty validation for the status option
sub validate_status
{
  # scalar (boolean)
       ! ref $_[0]

  # object with appropriate methods
  ||   ( blessed( $_[0] ) && $_[0]->can('print') && $_[0]->can('flush')  )

  # filehandle
  || 'GLOB' eq ref $_[0]

  # subroutine
  || 'CODE' eq ref $_[0]
}

1;

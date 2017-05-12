use Test::More tests => 6;

use strict;
use warnings;

use Astro::FITS::CFITSIO::CheckStatus;
use Astro::FITS::CFITSIO qw/ :longnames :constants /;
use PDL;

use Astro::FITS::CFITSIO::Simple qw/ rdfits /;

use Data::Dumper;

tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

my $filename = 'data/foo4.fits';



my @tform;
my @ttype;

my %cols = create_data();

#write_file( $filename, %cols );


# ninc => 1 to trap errors where the entire destination array was
# being reset to 0 before or'ing the new data, rather than just
# the slice appropriate for that chunk of rows.  since the data
# files are small, there's but one chunk, and this wasn't caught.

my %data = rdfits( $filename, { retinfo => 1,
				ninc => 1,
				dtypes => { c1 => 'logical',
					    c2 => 'logical',
					   },
			      } );

# modify c6 outgoing data as it's in bytes and rdfits should have read
# it back as long
{
  my $data = $cols{c6}{data}->long;
  $data->mslice([$_],[])->inplace->shiftleft(8 * $_,0) for 0..(($data->dims)[0])-1;
  $cols{c6}{data} = $data->borover;
}

while( my ( $name, $col ) = each %cols )
{
  ok( all ($col->{data} == $data{$name}{data}), $name );
}



sub write_file
{
  my ( $filename, %cols ) = @_;

  my $fptr = Astro::FITS::CFITSIO::create_file('!'.$filename, $status);

  $fptr->create_tbl( BINARY_TBL, 0, scalar keys %cols,
		     \@ttype,
		     \@tform,
		     undef,
		     'events',
		     $status );

  my $coln = 0;
  for my $col ( values %cols )
  {
    $coln++;
    $fptr->write_tdim( $coln, scalar @{$col->{tdim}}, $col->{tdim}, $status );
    $fptr->perlyunpacking(0);
    $fptr->write_col( $col->{dtype}, $coln, 1, 1, 10 * $col->{nelem}, $col->{data}->get_dataref, $status );
    $fptr->perlyunpacking(1);
  }
}

sub create_data
{
  my @cols;
  my $data;

  my $bits = pdl( 1, 0, 1, 0, 1, 0, 1, 0 );

  # 1x10 logical (logical bits)
  $cols{'c1'} =
  { data  => zeroes(byte,8,10)->xvals %2,
    tdim  => [8],
    nelem => 8,
    dtype => TBIT,
    name  => 'c1',
  };

  # 4x10 logical (logical bits)
  $data = zeroes(byte,8,4,10);
  $data->mslice([], [$_], []) .= $bits->rotate($_) for 0..3;

  $cols{'c2'} =
  { data  => $data,
    tdim  =>  [8,4],
    nelem => 32,
    dtype => TBIT,
    name  => 'c2',
  };


  # 1x10 bytes (packed bits)
  $data = zeroes(byte,10);
  $data .= 3;
  $data <<= $data->xvals;
  $cols{'c3'} =
  { data => $data,
    tdim => [8],
    nelem => 1,
    dtype => TBYTE,
    name  => 'c3',
  };

  # 4x10 bytes (packed bits)
  $data = zeroes(byte,4,10);
  $data .= pdl( 1, 3, 7, 15);
  $cols{'c4'} =
  { data => $data,
    tdim => [8,4],
    nelem => 4,
    dtype => TBYTE,
    name  => 'c4',
  };

  # 7x10 bytes (packed bits)
  # the tdim is set up to force rdfits to search 
  # for a matching type; it should fail and fall back to byte
  $data = zeroes(byte,7,10);
  $data .= pdl( 1, 3, 7, 15, 31, 63, 127);
  $cols{'c5'} =
  { data => $data,
    tdim => [56],
    nelem => 7,
    dtype => TBYTE,
    name  => 'c5',
  };

  # 4x10 bytes (packed bits)
  # set tdim so that rdfits turns this into long's
  $data = zeroes(byte,4,10);
  $data .= pdl( 1, 3, 7, 15);
  $cols{'c6'} =
  { data => $data,
    tdim => [32],
    nelem => 4,
    dtype => TBYTE,
    name  => 'c6',
  };

  for my $col ( values %cols )
  {
    my $repeat = 1;
    $repeat *= $_ foreach @{$col->{tdim}};
    $col->{repeat} = $repeat;
    push @tform, $repeat . 'X';

    push @ttype, $col->{name};
  }
  %cols;
}

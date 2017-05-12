use Test::More;

BEGIN {
  if ( unpack("h*", pack("s", 1)) =~ /^1/ )
  {
    plan skip_all => 'No little endian binary tables to test!';  
  }
  else
  { plan( tests => 168 ) }
};

BEGIN { use_ok( 'Astro::STSDAS::Table::Binary' ) }; 

use Astro::STSDAS::Table::Constants;

use warnings;
use strict;

my $tbl;

eval {
  $tbl = Astro::STSDAS::Table::Binary->new;
};
ok( !$@ && defined $tbl, 'new' );


my $pfx = 'binary_01';

ok( defined $tbl->open("$pfx.tab"), 'open' );

chk_par( $tbl, "$pfx.pars" );
chk_cols( $tbl, "$pfx.cd" );

# these rows and columns are really ok, but look like errors because
# of rounding differences when printing.
my %exceptions;
$exceptions{13, 16}++;
$exceptions{16, 16}++;
$exceptions{36, 16}++;
chk_data( $tbl, "$pfx.data", \%exceptions );


sub chk_data
{
  my ( $tbl, $data, $exceptions ) = @_;
  open( DATA, $data ) or die( "unable to open $data\n" );
  
  my $cols = $tbl->{cols};

  my $rows = $tbl->read_rows_array;
  my @row;
  my $idx = 0;
  my $error = "\n";
  while( <DATA> )
  {
    my @data = split;
    
    for ( my $cidx = 0; $cidx < $cols->ncols ; $cidx++ )
    {
      my $col = $cols->byidx($cidx + 1);
      my $format = $col->format;
      
      my $dval = $data[$cidx] ne 'INDEF' ? sprintf( "%$format", $data[$cidx] ) :
	'INDEF';
      my $val = $rows->[$idx][$cidx];
      $val = defined $val ? sprintf( "%$format", $val ) : 'INDEF';
      if ( $dval ne $val )
      {
	next if exists $exceptions->{$idx,$cidx};
	$error .= join('', 
		       "row $idx, col $cidx: >", $data[$cidx], "< >",
		       $rows->[$idx][$cidx], "<: >$dval<>$val<\n" );
      }
    }
    $idx++;
  }
  
  is( $error, "\n", "$data: compare" );
}


sub chk_par
{
  my ( $tbl, $pfile ) = @_;

  open ( PAR, $pfile ) or die( "unable to open $pfile\n" );
  
  while( <PAR> )
  {
    my $spar = $_;
    my ( $name , $type, $value ) = 
      map { my $x = $_; $x =~ s/^\s+//; $x =~ s/\s+$//; $x }
    (
     substr( $spar,  0,  8 -  0 + 1 ),
     substr( $spar,  9,  9 -  9 + 1 ),
     substr( $spar, 11 )
    );
    
    $type = $HdrType{ lc $type };
    
    my $par = $tbl->{pars}->byname( $name );
    isnt( $par, undef, "byname $name" );
    
    my $tag = "$pfile: par $name";
    
    is( $par->name,   $name, "$tag: name" );
    is( $par->type,   $type, "$tag: type" );
    is( $par->value,  $value, "$tag: value" );
  }

  close( PAR );
}


sub chk_cols
{
  my ( $tbl, $cdfile ) = @_;

  # Compare column info.  This is confusing. tdump produces output implying
  # a max 17 char column name, the binary table docs say 20, and the
  # tbset.h file says 79.  since we're reading tdump output, stick with 16
  open( CD, $cdfile ) or die( "unable to open $cdfile\n" );
  
  my $idx = 1;
  while( <CD> )
  {
    my $cd = $_;
    my ( $name , $type, $format, $units ) = 
      map { my $x = $_; $x =~ s/^\s+//; $x =~ s/\s+$//; $x }
    (
     substr( $cd,  0, 16 -  0 + 1 ),
     substr( $cd, 17, 17 - 17 + 1 ),
     substr( $cd, 18, 33 - 18 + 1 ),
     substr( $cd, 34 ) 
    );
    
    $type = $HdrType{ lc $type };
    $units = '' if $units eq '""';
    $format =~ s/^%//;
    
    my $col = $tbl->{cols}->byidx( $idx );
    
    my $tag = "$cdfile: col $idx";
    is( $col->name,   $name, "$tag: name" );
    is( $col->type,   $type, "$tag: type" );
    is( $col->format, $format, "$tag: format" );
    is( $col->units,  $units, "$tag: units" );
    
    $idx++;
  }
  
  close CD;
}

use Test::More tests => 6;

use IO::File;

BEGIN { use_ok( 'Data::LineBuffer' ); }


my @expected = 
(
 1, "line 1",
 2, "",
 3, "line 2",
 2, "insert 2",
 3, "insert 1",
 4, "line 3",
 5, "line 4",
 6, "line 5",
 6, "insert 3",
);

my @lines = 
(









);

# get data to load scalar and array
open FILE, "tst.in" or die( "unable to open test input\n" );
push @array, $_ while( <FILE> );
close FILE;

my $scalar = join( '', @array );

ok( eq_array( \@expected, doit( Data::LineBuffer->new( $scalar ) )),
    "scalar" );

ok( eq_array( \@expected, doit( Data::LineBuffer->new( \@array ) )), 
   "array" );

open FILE, "tst.in" or die( "unable to open test input\n" );
ok( eq_array( \@expected, doit( Data::LineBuffer->new( \*FILE ) )),
    "file glob" );
close FILE;

{
  my $fh = new IO::File 'tst.in' or die( "unable to open test input\n" );
  
  ok( eq_array( \@expected, doit( Data::LineBuffer->new( $fh ) )),
      "IO::File" );
  $fh->close;
}

# test subroutine by using filehandle
{
  my $fh = new IO::File 'tst.in' or die( "unable to open test input\n" );
  
  ok( eq_array( \@expected, doit( Data::LineBuffer->new( sub { scalar <$fh> } ) )),
      "subroutine" );
  $fh->close;
}

sub doit
{
  my $it = shift;

  my @results;

  push @results, $it->pos, $it->get for ( 1..3 );

  $it->unget( "insert 1\n" );
  $it->unget( "insert 2\n" );

  push @results, $it->pos, $it->get for ( 1..5 );
  
  $it->unget( "insert 3\n" );

  push @results, $it->pos, $it->get;

#  my @c = @results;
#  my ( $line, $string );
#  print STDERR "$line $string\n" while ($line,$string) = splice(@c, 0, 2 );

  \@results;
}


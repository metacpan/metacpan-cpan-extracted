# -*- mode: perl -*-

use Test::More tests => 6;
#use Test::More qw(no_plan);

our ( $debugf, $BZIP );

do './t/lib.pl';

my $PREFIX = catfile( qw(t 01-tmp) );

#display_file( 'words1' );

foreach my $insuffix ( qw( ref bz2 ) ) {
  my $outsuffix = $insuffix eq 'ref' ? 'bz2' : 'ref';
  foreach my $sampleno ( 1..3 ) {
    my $opts = $insuffix eq 'ref' ? "-$sampleno" : $sampleno < 3 ? "-d" : "-ds";

    system( "$::BZIP $opts  < sample$sampleno.$insuffix > $PREFIX-sample$sampleno-tst.$outsuffix" );
    ok ( compare_binary_files( "sample$sampleno.$outsuffix", "$PREFIX-sample$sampleno-tst.$outsuffix" ),
	 ($insuffix eq 'ref' ? 'compress' : 'uncompress'). " sample$sampleno.$insuffix successful" );
  }
}

#display_file( 'words3' );


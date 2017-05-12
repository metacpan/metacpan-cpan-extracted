#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';

use DataExtract::FixedWidth;
use IO::File;

use Test::More tests => 1;

use File::Spec;
my $file = File::Spec->catfile( 't', 'data', 'Dealermade.txt' );
my $fh = IO::File->new( $file );
my @lines = grep /\w/, $fh->getlines;
s/\s+$// for @lines;

my $defw = DataExtract::FixedWidth->new({
	heuristic => \@lines
	, cols    => [ qw/stock year make model body color vin price/ ]
	, header_row => undef
});

my @rows;
foreach my $line ( @lines ) {
	push @rows, $defw->parse_hash( $line );
}

my $VAR1 = [
  {
    'body' => '4DR SUV',
    'color' => 'WHITE',
    'make' => 'FORD',
    'model' => 'ESCAPE',
    'price' => '28275.00',
    'vin' => '1FMCU04148KB05995',
    'stock' => '000KP209',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'GRAY',
    'make' => 'FORD',
    'model' => 'ESCAPE',
    'price' => '27640.00',
    'vin' => '1FMCU04168KD84379',
    'stock' => '000KP221',
    'year' => '08'
  },
  {
    'body' => 'CREW CAB',
    'color' => 'BLUE',
    'make' => 'FORD',
    'model' => 'EXP SPTRAC',
    'price' => '26870.00',
    'vin' => '1FMEU31E98UA60445',
    'stock' => '000KL059',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'SILVER',
    'make' => 'FORD',
    'model' => 'EXPEDITION',
    'price' => '32930.00',
    'vin' => '1FMFU15528LA25237',
    'stock' => '000KM126',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'Red',
    'make' => 'FORD',
    'model' => 'EXPEDITION',
    'price' => '34985.00',
    'vin' => '1FMFU15558LA19982',
    'stock' => '*000KM056',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'BLUE',
    'make' => 'FORD',
    'model' => 'EXPEDITION',
    'price' => '35595.00',
    'vin' => '1FMFU15568LA61495',
    'stock' => '000KM183',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'BLUE',
    'make' => 'FORD',
    'model' => 'EXPEDITION',
    'price' => '34300.00',
    'vin' => '1FMFU15588LA61210',
    'stock' => '000KM178',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'WHITE',
    'make' => 'FORD',
    'model' => 'EXPEDTN EL',
    'price' => '37140.00',
    'vin' => '1FMFK155X8LA67709',
    'stock' => '000KM199',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'WHITE',
    'make' => 'FORD',
    'model' => 'EXPEDTN EL',
    'price' => '37390.00',
    'vin' => '1FMFK15528LA72600',
    'stock' => '*000KM207',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'BLACK',
    'make' => 'FORD',
    'model' => 'EXPEDTN EL',
    'price' => '36655.00',
    'vin' => '1FMFK15548LA15184',
    'stock' => '000KM198',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'SILVER',
    'make' => 'FORD',
    'model' => 'EXPEDTN EL',
    'price' => '44630.00',
    'vin' => '1FMFK19598LA61068',
    'stock' => '000KM176',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'BLUE',
    'make' => 'FORD',
    'model' => 'EXPLORER',
    'price' => '26890.00',
    'vin' => '1FMEU63EX8UA67046',
    'stock' => '000KL044',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'SILVER',
    'make' => 'FORD',
    'model' => 'EXPLORER',
    'price' => '28635.00',
    'vin' => '1FMEU63E08UB10566',
    'stock' => '000KL074',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'RED',
    'make' => 'FORD',
    'model' => 'EXPLORER',
    'price' => '26890.00',
    'vin' => '1FMEU63E88UA67109',
    'stock' => '000KL048',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'BLUE',
    'make' => 'FORD',
    'model' => 'EXPLORER',
    'price' => '28400.00',
    'vin' => '1FMEU63E88UA91359',
    'stock' => '000KL066',
    'year' => '08'
  },
  {
    'body' => '4DR SUV',
    'color' => 'BLACK',
    'make' => 'FORD',
    'model' => 'EXPLORER',
    'price' => '28075.00',
    'vin' => '1FMEU63E88UB10573',
    'stock' => '000KL075',
    'year' => '08'
  },
  {
    'body' => 'CREW CAB',
    'color' => 'BLACK',
    'make' => 'FORD',
    'model' => 'F-150',
    'price' => '36980.00',
    'vin' => '1FTPW12V08FC01434',
    'stock' => '*000KQ385',
    'year' => '08'
  },
  {
    'body' => 'CREW CAB',
    'color' => 'BROWN',
    'make' => 'FORD',
    'model' => 'F-150',
    'price' => '35408.28',
    'vin' => '1FTPW12V08KC36417',
    'stock' => '000KQ138',
    'year' => '08'
  },
  {
    'body' => 'CREW CAB',
    'color' => 'BLACK',
    'make' => 'FORD',
    'model' => 'F-150',
    'price' => '35408.28',
    'vin' => '1FTPW12V08KC47143',
    'stock' => '000KQ135',
    'year' => '08'
  },
  {
    'body' => 'CREW CAB',
    'color' => 'BLACK',
    'make' => 'FORD',
    'model' => 'F-150',
    'price' => '43205.00',
    'vin' => '1FTRW14518FB28676',
    'stock' => '000KQ286',
    'year' => '08'
  }
];

is_deeply( $VAR1 , \@rows , 'deep test using heuristic and supplied cols' );

1;

#!/usr/bin/env perl
use lib '../../../lib';
use DateTimeX::Format::Excel;

# From an Excel date number

my		$parser = DateTimeX::Format::Excel->new();
print	$parser->parse_datetime( 25569 )->ymd ."\n"; # prints 1970-01-01
my		$datetime = $parser->parse_datetime( 37680 );
print	$datetime->ymd() ."\n";     # prints 2003-02-28
		$datetime = $parser->parse_datetime( 40123.625 );
print	$datetime->iso8601() ."\n"; # prints 2009-11-06T15:00:00

# And back to an Excel number from a DateTime object

use DateTime;
my		$dt = DateTime->new( year => 1979, month => 7, day => 16 );
my		$daynum = $parser->format_datetime( $dt );
print 	$daynum ."\n"; # prints 29052

my 		$dt_with_time = DateTime->new( year => 2010, month => 7, day => 23
								, hour => 18, minute => 20 );
my 		$excel_date = $parser->format_datetime( $dt_with_time );
print 	$excel_date ."\n"; # prints 40382.763888889
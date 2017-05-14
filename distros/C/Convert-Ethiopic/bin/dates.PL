#!/usr/bin/perl -w

use strict;
use Convert::Ethiopic::Date;

# use diagnostics;

main:
{


	print "1/1/2001 EU => 23/4/1993 EC\n";
	my $d = new Convert::Ethiopic::Date ( 1, 1, 2001 );

	my $n = $d->toEthiopic;
	my ( $day, $month, $year ) = ( $n->{date}, $n->{month}, $n->{year} );

	print "$day/$month/$year\n";
	print "$n->{date}-$n->{month}-$n->{year}\n";

	$d->{langOut} = 0;
	print $d->getMonthName;
	print $d->getDayOfWeek;

	print "11/9/2000 EU => 1/1/1993 EC\n";
	( $day, $month, $year ) = $d->toEthiopic ( 11, 9, 2000 );

	print "$day/$month/$year\n";

	print "11/9/2000 EU => 1/1/1993 EC\n";
	my $e = new Convert::Ethiopic::Date ( );

	( $day, $month, $year ) =  $e->convert ( 11, 9, 2000 );
	#
	# should we allow this as well?
	#
	# ( $day, $month, $year ) =  $e->convert  ( cal => "ethio", date => 11, month => 9, year => 2000 );

	print "$day/$month/$year\n";
	# print "$e->{date}-$e->{month}-$e->{year}\n";

	print "1/1/1993 EC => 11/9/2000 EU\n";
	my $f = new Convert::Ethiopic::Date ( cal => "ethio", date => 1, month => 1, year => 1993 );

	( $day, $month, $year ) =  $f->convert;

	print "$day/$month/$year\n";

	$f->{langOut} = 0;
	print $f->getMonthName;
	print $f->getDayOfWeek;

	#
	# "today" gets current date in european calendar
	#
	my $g = new Convert::Ethiopic::Date ( "today" )->convert;
	print "Today is:\n";	
	print "$g->{date}-$g->{month}-$g->{year}\n";

}

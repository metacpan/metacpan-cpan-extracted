#!/usr/bin/perl -I. -w

require Date::Ethiopic;
use strict;

if ( $] >= 5.007 ) {
	binmode (STDOUT, ":utf8");
	binmode (STDERR, ":utf8");
}

print "Testing[01]:  ( day => 29, month => 6, year => 1995 )\n";
my $ethio = new Date::Ethiopic ( day => 29, month => 6, year => 1995 );
my ($d,$m,$y) = $ethio->gregorian;
print "  Gregorian: $d/$m/$y\n";
print "  Epoch    : ", $ethio->epoch,"\n";

print "Testing[02]:  ( epoch => time )\n";
$ethio = new Date::Ethiopic ( epoch => time );
print "  Ethiopic : ", $ethio->day,"/",$ethio->month,"/",$ethio->year,"\n";
($d,$m,$y) = $ethio->gregorian;
print "  Gregorian: $d/$m/$y\n";

print "Testing[03]:  ( epoch => time, calscale => \"gregorian\" )\n";
my $grego = new Date::Ethiopic ( epoch => time, calscale => "gregorian" );
print "  Ethiopic : ", $grego->day,"/",$grego->month,"/",$grego->year,"\n";
($d,$m,$y) = $grego->gregorian;
print "  Gregorian: $d/$m/$y\n";

print "Testing[04]: ical => '19950629'\n";
$ethio = new Date::Ethiopic ( ical => '19950629' );
print "  Ethiopic : ", $ethio->day,"/",$ethio->month,"/",$ethio->year,"\n";
($d,$m,$y) = $ethio->gregorian;
print "  Gregorian: $d/$m/$y\n";

print "Testing[05]: ical => '19950629', calscale => 'ethiopic'\n";
$ethio = new Date::Ethiopic ( ical => '19950629', calscale => 'ethiopic' );
print "  Ethiopic : ", $ethio->day,"/",$ethio->month,"/",$ethio->year,"\n";
($d,$m,$y) = $ethio->gregorian;
print "  Gregorian: $d/$m/$y\n";

print "Testing[06]: ical => '20030308', calscale => 'gregorian'\n";
$grego = new Date::Ethiopic ( ical => '20030308', calscale => 'gregorian' );
print "  Gregorian: ", $grego->day,"/",$grego->month,"/",$grego->year,"\n";
($d,$m,$y) = $grego->gregorian;
print "  Ethiopic : $d/$m/$y\n";

print "Testing[07]:  ( day => '08', month => '03', year => '2003', calscale => 'gregorian' )\n";
$grego = new Date::Ethiopic ( day => '08', month => '03', year => '2003', calscale => "gregorian" );
print "  Gregorian: ", $grego->day,"/",$grego->month,"/",$grego->year,"\n";
($d,$m,$y) = $grego->gregorian;
print "  Ethiopic : $d/$m/$y\n";

require Date::ICal;
print "Testing[08]:  ( \$ical )\n";
$grego = new Date::ICal ( ical => '20030308' );
$ethio = new Date::Ethiopic ( $grego );
print "  Ethiopic : ", $ethio->day,"/",$ethio->month,"/",$ethio->year,"\n";
($d,$m,$y) = $ethio->gregorian;
print "  Gregorian: $d/$m/$y\n";

print "Testing[09]:  ->toGregorian\n";
$ethio = new Date::Ethiopic ( ical => '19950629' );
$grego = $ethio->toGregorian;
print "  Got a \"", ref($grego), "\"\n";
print "  Gregorian : ", $grego->day,"/",$grego->month,"/",$grego->year,"\n";

require Date::Ethiopic::ET::am;
my $amh = new Date::Ethiopic::ET::am( ical => '19950629' );
print "Testing[10]: ", $amh->name, "\n";
print "  Ethiopic : ", $amh->day,"/",$amh->month,"/",$amh->year,"\n";
print "  Day   Name: ", $amh->day_name, "\n";
print "  Month Name: ", $amh->month_name, "\n";
$amh->useTranscription ( 1 );
print "  Long  Date: ", $amh->long_date, "\n";
$amh->useTranscription ( 0 );
print "  Long  Date: ", $amh->long_date, "\n";
print "  Long  Date: ", $amh->long_date('ethio'), "\n";
$amh->useTranscription ( 1 );
print "  Full  Date: ", $amh->full_date, "\n";
$amh->useTranscription ( 0 );
print "  Full  Date: ", $amh->full_date, "\n";
print "  Full  Date: ", $amh->full_date('ethio'), "\n";
print "  The Season: ", $amh->season, "\n";
print "  Day Star  : ", $amh->dayStar, "\n";
print "  Month Star: ", $amh->monthStar, "\n";
print "  Year Star : ", $amh->yearStar, "\n";
my $ly = ( $amh->isLeapYear ) ? "a" : "not a";
print "  Year Name : ", $amh->yearName, " is $ly leap year.\n";


# This is rather large
#
#print "Testing[11]:  Getting Tsome List:\n";
#
#my @array = $amh->tsomes;
#
#foreach (@array) {
# 	print "  Full  Date[$_->{_tsome_name}]: ", $_->full_date, "\n";
#}
use utf8;


require Date::Ethiopic::ET::qim;
my $qim = new Date::Ethiopic::ET::qim( ical => '19950629' );
print "Testing[11]: ", $qim->name, "\n";
print "  Ethiopic : ", $qim->day,"/",$qim->month,"/",$qim->year,"\n";
print "  Day   Name: ", $qim->day_name, "\n";
print "  Month Name: ", $qim->month_name, "\n";


require Date::Ethiopic::ER::byn;
my $byn = new Date::Ethiopic::ER::byn( ical => '19950629' );
print "Testing[12]: ", $byn->name, "\n";
print "  Ethiopic : ", $byn->day,"/",$byn->month,"/",$byn->year,"\n";
print "  Day   Name: ", $byn->day_name, "\n";
print "  Month Name: ", $byn->month_name, "\n";


require Date::Ethiopic::ER::gez;
my $gez = new Date::Ethiopic::ER::gez ( ical => '19950629' );
print "Testing[13]: ", $gez->name, "\n";
print "  Ethiopic : ", $gez->day,"/",$gez->month,"/",$gez->year,"\n";
print "  Day   Name: ", $gez->day_name, "\n";
print "  Month Name: ", $gez->month_name, "\n";


require Date::Ethiopic::ET::har;
my $har = new Date::Ethiopic::ET::har ( ical => '19950629' );
print "Testing[13]: ", $har->name, "\n";
print "  Ethiopic : ", $har->day,"/",$har->month,"/",$har->year,"\n";
print "  Day   Name: ", $har->day_name, "\n";
print "  Month Name: ", $har->month_name, "\n";


require Date::Ethiopic::ET::gru;
my $gru = new Date::Ethiopic::ET::gru( ical => '19950629' );
print "Testing[14]: ", $gru->name, "\n";
print "  Ethiopic : ", $gru->day,"/",$gru->month,"/",$gru->year,"\n";
print "  Day   Name: ", $gru->day_name, "\n";
print "  Month Name: ", $gru->month_name, "\n";


require Date::Ethiopic::ET::guy;
my $guy = new Date::Ethiopic::ET::guy( ical => '19950629' );
print "Testing[15]: ", $guy->name, "\n";
print "  Ethiopic : ", $guy->day,"/",$guy->month,"/",$guy->year,"\n";
print "  Day   Name: ", $guy->day_name, "\n";
print "  Month Name: ", $guy->month_name, "\n";


require Date::Ethiopic::ER::tig;
my $tig = new Date::Ethiopic::ER::tig( ical => '19950629' );
print "Testing[16]: ", $tig->name, "\n";
print "  Ethiopic : ", $tig->day,"/",$tig->month,"/",$tig->year,"\n";
print "  Day   Name: ", $tig->day_name, "\n";
print "  Month Name: ", $tig->month_name, "\n";


require Date::Ethiopic::ET::ti;
my $tir = new Date::Ethiopic::ET::ti( ical => '19950629' );
print "Testing[17]: ", $tir->name, "\n";
print "  Ethiopic : ", $tir->day,"/",$tir->month,"/",$tir->year,"\n";
print "  Day   Name: ", $tir->day_name, "\n";
print "  Month Name: ", $tir->month_name, "\n";


require Date::Ethiopic::ET::zgu;
my $zgu = new Date::Ethiopic::ET::zgu( ical => '19950629' );
print "Testing[17]: ", $zgu->name, "\n";
print "  Ethiopic : ", $zgu->day,"/",$zgu->month,"/",$zgu->year,"\n";
print "  Day   Name: ", $zgu->day_name, "\n";
print "  Month Name: ", $zgu->month_name, "\n";


__END__

=head1 NAME

dates.pl - Conversion Demonstration for 17 dates.

=head1 SYNOPSIS

./dates.pl

=head1 DESCRIPTION

A demonstrator script to illustrate usage of L<Date::Ethiopic> and friends.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut

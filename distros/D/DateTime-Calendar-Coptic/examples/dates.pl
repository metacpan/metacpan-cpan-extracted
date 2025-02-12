#!/usr/bin/perl -I. -w

use strict;
use utf8;
require DateTime::Calendar::Coptic;

binmode(STDOUT, ":utf8");

print "Testing[01]:  ( day => 28, month => 7, year => 1719 )\n";
my $coptic = new DateTime::Calendar::Coptic ( day => 28, month => 7, year => 1719 );
print "  Day   Name: ", $coptic->day_name, "\n";
print "  Month Name: ", $coptic->month_name, "\n";

print "Testing[02]:  ( day => 28, month => 7, year => 1719, language => \"ar\" )\n";
my $arabic = new DateTime::Calendar::Coptic ( day => 28, month => 7, year => 1719, language => "ar" );
print "  Day   Name: ", $arabic->day_name, "\n";
print "  Month Name: ", $arabic->month_name, "\n";

print "Testing[03]:  ( day => 28, month => 7, year => 1719, language => \"en\" )\n";
my $english = new DateTime::Calendar::Coptic ( day => 28, month => 7, year => 1719, language => "en" );
print "  Day   Name: ", $english->day_name, "\n";
print "  Month Name: ", $english->month_name, "\n";

print "Testing[04]:  \$coptic->gregorian\n";
my ($d,$m,$y) = $coptic->gregorian;
print "  Gregorian : $d/$m/$y\n";

print "Testing[05]:  ->toGregorian\n";
my $grego = $coptic->toGregorian;
print "  Got a \"", ref($grego), "\"\n";
print "  Gregorian : ", $grego->day,"/",$grego->month,"/",$grego->year,"\n";

print "Testing[06]:  ( day => 5, month => 4, year => 2003, calscale => \"gregorian\" )\n";
$grego = new DateTime::Calendar::Coptic ( day => 5, month => 4, year => 2003, calscale => "gregorian" );
print "  Coptic   : ", $grego->day,"/",$grego->month,"/",$grego->year,"\n";
($d,$m,$y) = $grego->gregorian;
print "  Gregorian: $d/$m/$y\n";

print "Testing[07]:  ( day => 28, month => 7, year => 1995, calscale => \"ethiopic\" )\n";
$grego = new DateTime::Calendar::Coptic ( day => 28, month => 7, year => 1995, calscale => "ethiopic" );
print "  Coptic   : ", $grego->day,"/",$grego->month,"/",$grego->year,"\n";
($d,$m,$y) = $grego->gregorian;
print "  Gregorian: $d/$m/$y\n";

print "Testing[08]:  \$coptic->utc_rd_values\n";
my ($rd) = $coptic->utc_rd_values;
print "         RD: $rd\n";

# $coptic->useTranscription ( 1 );

print "Testing[09]:  \$coptic->full_date\n";
print "  Full Date: ", $coptic->full_date, "\n";

print "Testing[09]:  \$coptic->full_date ( 1 ) # extra full!\n";
print "  Full Date: ", $coptic->full_date ( 1 ), "\n";

print "Testing[10]:  \$coptic->medium_date\n";
print "  Med. Date: ", $coptic->medium_date, "\n";

print "Testing[11]:  \$coptic->long_date\n";
print "  Long Date: ", $coptic->long_date, "\n";


__END__

=head1 NAME

dates.pl - 11 Demonstrations of Coptic Dates and Conversions.

=head1 SYNOPSIS

./dates.pl

=head1 DESCRIPTION

A demonstrator script to illustrate usage of L<DateTime::Calendar::Coptic>.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut

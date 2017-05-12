# German.pm
#
# (c) 2003 Christian Winter <thepoet@a-za-z0-9.de>
# All rights reserved. This program is free software; you can redistribute
# and/or modify it under the same terms as perl itself.

=head1 NAME

Date::Spoken::German - Output dates as Latin1 text as you would speak it

=head1 SYNOPSIS

 use Date::Spoken::German;

 print timetospoken( time() );
 print datetospoken( $DAY, $MONTH, $YEAR );

=head1 DESCRIPTION

This module provides you with functions to easily convert a date (given
as either integer values for day, month and year or as a unix timestamp)
to its representation as German text, like you would read it aloud.

=head1 EXPORTABLE TAGS

:ALL    - all helper methods are also exported into the callers namespace

=head1 FUNCTIONS

=head2 Exported by default

=over 2

=item B<timetospoken( $TIMESTAMP )>

In scalar context, return a string consisting of the text
representation of the date in the given unix timestamp,
like e.g. "dreizehnter Mai zweitausenddrei".

In list context, returns the three words of the string as a list.

=item B<datetospoken( $DAY, $MONTH, $YEAR )>

Takes the values for day of month, month and year as integers
(month starting with B<1>) and gives the same return values as
I<timetospoken>.

=back

=head2 Exported by :ALL

=over 2

=item B<yeartospoken( $YEAR )>

Takes a year (absolute integer value) as input and returns the
text representation in German.

=item B<monthtospoken( $MONTH )>

Takes a month (integer value, January = 1) as input and returns
the text representation in German.

=item B<daytospoken( $DAY )>

Converts a day number to its German text representation.

=back

=head1 KNOWN ISSUES

None at the moment.

=head1 BUGS

Please report all bugs to the author of this module:
Christian Winter <thepoet@a-za-z0-9.de>

=for html <a href="mailto:thepoet@a-za-z0-9.de?subject=Bug%20in%20Date::Spoken::German">Mail a Bug</a>

=head1 CREDITS

To Larry Wall for Perl itself, and to all developers out there
contributing to the Perl community. Special thanks to all regulars
in the usenet perl groups for giving me a lot of hints that helped
me understand what Perl can do.

=head1 SEE ALSO

Type B<perldoc perl> to get info on Perl itselft.
Type B<perldoc perlmod> to get info on Perl modules.

=cut

package Date::Spoken::German;

use encoding 'latin1';
use POSIX;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(datetospoken timetospoken);
%EXPORT_TAGS = ( ALL => [qw(yeartospoken datetospoken timetospoken monthtospoken daytospoken)] );

our $VERSION = "0.05";
our $AUTHOR = 'Christian Winter <thepoet@a-za-z0-9.de>';

my %cipher = (	1 => "ein", 2 => "zwei", 3 => "drei", 4 => "vier", 5 => "fünf", 6 => "sechs", 7 => "sieben",
		8 => "acht", 9 => "neun", 10 => "zehn", 11 => "elf", 12 => "zwölf", 16 => "sechzehn", 17 => "siebzehn", 18 => "achzehn" );
my %specialcipher = ( 1 => "ers", 3 => "drit", 7 => "sieb", 8 => "ach" );
my %tens = (	1 => "zehn", 2 => "zwanzig", 3 => "dreissig", 6 => "sechzig", 7 => "siebzig", 8 => "achzig" );
my %month = (	1 => "Januar", 2 => "Februar", 3 => "März", 4 => "April", 5 => "Mai", 6 => "Juni",
		7 => "Juli", 8 => "August", 9 => "September", 10 => "Oktober", 11 => "November", 12 => "Dezember" );

sub yeartospoken
{
	my $year = shift;
	(my $tens = $year) =~ s/^.*(\d\d)$/$1/;
	my $hundreds = "";
	if( $year < 10 ) {
		$year = $cipher{$year} || "null";
	} else {
		if( $tens == 0 ) {
			$tens = "";
		} elsif( ($tens % 10) == 0 ) {
			$tens =~ s/(.)(.)/$tens{$1}/;
		} else {
			if( $tens < 10 ) {
				$tens =~ s/(.)(.)/$cipher{$2}/;
			} else {
				$tens =~ s/(.)(.)/$cipher{"$1$2"} || $cipher{$2}.(($1==1)?$tens{$1}:"und".$tens{$1})/e;
			}
		}
		if( $year >= 100 ) {
			($hundreds = $year) =~ s/^(.?.)..$/$1/;
			if( $hundreds >= 20 || $hundreds == 10 ) {
				$hundreds =~ s/(.)(.)/$cipher{$1}."tausend".(($2>0)?$cipher{$2}."hundert":"")/ex;
			} else {
				if( $hundreds > 10 ) {
					$hundreds =~ s/(.)(.)/($cipher{"$1$2"} || $cipher{$2}."zehn")."hundert"/e;
				} else {
					$hundreds = $cipher{$hundreds}."hundert";
				}
			}
		}
	}
	return $hundreds.$tens;
}

sub monthtospoken
{
	my $monat = shift;
	return $month{$monat};
}

sub daytospoken
{
	my $tag = shift;
	$endung = ($tag > 19)?"ster":"ter";
	if( $tag >= 10 ) {
		$tag =~ s/(.)(.)/$cipher{"$1$2"} || (($2>0)?$cipher{$2}.(($1>1)?"und":""):"").$tens{$1}/ex;
	} else {
		$tag = $specialcipher{$tag} || $cipher{$tag};
	}
	return $tag.$endung;
}

sub datetospoken
{
	my ($tag, $monat, $jahr) = @_;
	if( wantarray ) {
		return daytospoken($tag), monthtospoken($monat), yeartospoken($jahr);
	} else {
		return daytospoken($tag)." ".monthtospoken($monat)." ".yeartospoken($jahr);
	}
}

sub timetospoken
{
	my( $tag, $monat, $jahr) = (gmtime( shift || time() ))[3,4,5];
	return datetospoken($tag, $monat+1, 1900+$jahr);
}

1;

# Date::Decade.pm
#
# Copyright (c) 2001 Michael Diekmann <michael.diekmann@undef.de>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Documentation could be found at the bottom or use (after install):
# > perldoc Date::Decade

package Date::Decade;

require 5.003_03;
require Exporter;

use strict;
use Carp;
use vars qw(@EXPORT_OK %EXPORT_TAGS @ISA $VERSION
	@arr_Days_in_Decade
);

#use Date::Pcalc 1.2 qw(
#	leap_year
#	check_date
#	Day_of_Year
#);
use Date::Calc 4.3 qw(
	leap_year
	check_date
	Day_of_Year
);

@ISA = qw(Exporter);

# we export nothing by default :)
@EXPORT_OK = qw(
	Days_in_Decade
	Decade_of_Year
	Decade_of_Month
);
%EXPORT_TAGS = (all => [@EXPORT_OK] );

@arr_Days_in_Decade = (
[ 10,10,11 , 10,10,8 , 10,10,11 , 10,10,10 , 10,10,11 , 10,10,10 , 10,10,11 , 10,10,11 , 10,10,10 , 10,10,11 , 10,10,10 , 10,10,11 ],
[ 10,10,11 , 10,10,9 , 10,10,11 , 10,10,10 , 10,10,11 , 10,10,10 , 10,10,11 , 10,10,11 , 10,10,10 , 10,10,11 , 10,10,10 , 10,10,11 ]
);

$VERSION = '0.33';

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

sub Days_in_Decade {
	my $year = shift;
	my $decade = shift;

	if ($year > 0) {
		if (($decade >= 1) && ($decade <= 36)) {
			return $arr_Days_in_Decade[leap_year($year)][$decade-1];
		}
		else {
			DATECALC_DECADE_ERROR("Days_in_Decade");
		}
	}
	else {
		DATECALC_YEAR_ERROR("Days_in_Decade");
	}
}

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

sub Decade_of_Year {
	my $year = shift;
	my $month = shift;
	my $day = shift;

	if (check_date($year, $month, $day)) {
		my $n_days = Day_of_Year($year,$month,$day);
		my $decade = _round($n_days / 10);
		if ($decade > 36) {
			$decade = 36;
		}
		elsif ($decade == 0) {
			$decade = 1;
		}
		return $decade;
	}
	else {
		DATECALC_DATE_ERROR("Decade_of_Year");
	}
}

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

sub Decade_of_Month {
	my $year = shift;
	my $month = shift;
	my $day = shift;

	if (check_date($year, $month, $day)) {
		my $decade = ($day - ($day % 10)) / 10 + 1;
		if ($decade >= 4) {
			$decade = 3;
		}
		return $decade;
	}
	else {
		DATECALC_DATE_ERROR("Decade_of_Month");
	}
}

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

sub _round {
	$_ = shift;
	my $x = int($_);
	if (($_ >= 0) && (($_ - $x) >= 0.5)) {
		$x++;
	}
	elsif (($_ < 0) && (($x - $_) >= 0.5)) {
		$x--;
	}
	return $x;
}

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

sub DATECALC_DECADE_ERROR {
	my ($name) = @_;
	croak("Date::Pcalc::${name}(): decade out of range");
}

sub DATECALC_DATE_ERROR {
	my ($name) = @_;
	croak("Date::Pcalc::${name}(): not a valid date");
}

1;

__END__

#///////////////////////////////////////////////////////////////////////#
#									#
#///////////////////////////////////////////////////////////////////////#

=head1 NAME

Date::Decade - Decade calculations



=head1 SYNOPSIS

  use Date::Decade qw(
	Days_in_Decade
	Decade_of_Year
	Decade_of_Month
  );

  use Date::Decade qw(:all);

 Days_in_Decade
   $days_in_decade = Days_in_Decade($year,$decade);

 Decade_of_Year
   $decade_of_year = Decade_of_Year($year,$month,$day);

 Decade_of_Month
   $decade_of_month = Decade_of_Month($year,$month,$day);



=head1 DESCRIPTION

  $days_in_decade = Days_in_Decade($year,$decade);
    This function returns how many days a given decade
    have.

  $decade_of_year = Decade_of_Year($year,$month,$day);
    This function returns which decade it is on a
    given date (from the 1. January).


  $decade_of_month = Decade_of_Month($year,$month,$day);
    This function returns which decade it is on a
    given month.



=head1 PREREQUISITES

This module requires perl 5.003_03 or later and:

Date:Calc 4.3 by Steffen Beyer <sb@engelschall.com>,
http://www.cpan.org/authors/id/STBEY/Date-Calc-4.3.tar.gz

or (with some changes)

Date:Pcalc 1.2 by J. David Eisenberg <nessus@best.com>,
http://www.cpan.org/authors/id/STBEY/Date-Pcalc-1.2.tar.gz



=head1 BUGS

No Bugs known for now. ;)



=head1 HISTORY

=item - 2001-08-22 / 0.33

Errors in the file Makefile.PL corrected.


=item - 2001-08-22 / 0.32

First beta-release



=head1 AUTHOR

Michael Diekmann, <michael.diekmann@undef.de>



=head1 COPYRIGHT

Copyright (c) 2001 Michael Diekmann <michael.diekmann@undef.de>. All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.



=head1 SEE ALSO

Date::Calc or Date::Pcalc, perl(1).

=cut

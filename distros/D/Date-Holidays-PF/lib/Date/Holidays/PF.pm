package Date::Holidays::PF;

use strict;
use warnings;
use Time::Local;
use Date::Easter;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_pf_holiday get_easter get_ascension get_pentecost get_vendredisaint get_lundipaques);

our $VERSION = '0.01';
use utf8;

sub get_easter {
	my ($year) = @_;
	return Date::Easter::easter($year);
}

sub get_ascension {
	my ($year) = @_;
	return _compute_date_from_easter($year, 39);
}

sub get_pentecost {
	my ($year) = @_;
	return _compute_date_from_easter($year, 50);
}

sub get_vendredisaint {
        my ($year) = @_;
        return _compute_date_from_easter($year, -2);
}

sub get_lundipaques {
        my ($year) = @_;
        return _compute_date_from_easter($year, 1);
}

sub _compute_date_from_easter {
	my ($year, $delta) = @_;

	my ($easter_month, $easter_day) = get_easter($year);
	my $easter_date = Time::Local::timelocal(0, 0, 1, $easter_day, $easter_month - 1, $year - 1900);
	my ($date_month, $date_day) = (localtime($easter_date + $delta * 86400))[4, 3];
	$date_month++;

	return ($date_month, $date_day);
}

sub is_pf_holiday {
	my ($year, $month, $day) = @_;

	if ($day == 1 and $month == 1) { return "Nouvel an"; }
	elsif ($day == 5 and $month == 3) { return "Arrivé de l'évangile"; }
	elsif ($day == 1 and $month == 5) { return "Fête du travail"; }
	elsif ($day == 8 and $month == 5) { return "Armistice 39-45"; }
	elsif ($day == 29 and $month == 6) { return "Fête de l'autonomie"; }
	elsif ($day == 14 and $month == 7) { return "Fête nationale"; }
	elsif ($day == 15 and $month == 8) { return "Assomption"; }
	elsif ($day == 1 and $month == 11) { return "Toussaint"; }
	elsif ($day == 11 and $month == 11) { return "Armistice 14-18"; }
	elsif ($day == 25 and $month == 12) { return "Noël"; }
	else {
		my ($easter_month, $easter_day) = get_easter($year);
		my ($vendredisaint_month, $vendredisaint_day) = _compute_date_from_easter($year, -2);
		my ($lundipaques_month, $lundipaques_day) = _compute_date_from_easter($year, 1);
		my ($ascension_month, $ascension_day) = _compute_date_from_easter($year, 39);
		my ($pentecost_month, $pentecost_day) = _compute_date_from_easter($year, 50);

		if ($day == $easter_day and $month == $easter_month) { return "Pâques"; }
		elsif ($day == $lundipaques_day and $month == $lundipaques_month) { return "Lundi de pâques"; }
		elsif ($day == $vendredisaint_day and $month == $vendredisaint_month) { return "Vendredi saint"; }
		elsif ($day == $ascension_day and $month == $ascension_month) { return "Ascension"; }
		elsif ($day == $pentecost_day and $month == $pentecost_month) { return "Lundi de Pentecôte"; }
	}
}

1;

__END__

=head1 NAME

Date::Holidays::PF - Determine French Polynesia holidays

=head1 SYNOPSIS

  use Date::Holidays::PF;
  for my $year (2017 .. 2027) {
  	print $year,"\n";
  	my @JF = ((1,1),(3,5),get_vendredisaint($year),get_lundipaques($year),(5,1),(5,8),get_ascension($year),get_pentecost($year),(6,29),(7,14),(8,15),(11,1),(11,11),(12,25));
  	use List::Util qw( pairs );
  	foreach my $pair ( pairs @JF) {
  		my ($month, $day)= @$pair;
  		print "$year,$month,$day ", is_pf_holiday($year,$month,$day),"\n";
  	}
  }


=head1 DESCRIPTION

is_pf_holiday method return true value when the day is holiday.

There is 14 holidays in French Polynesia.

=over 4

=item * 1er janvier : Nouvel an

=item * 3 mars : arrivée de l'évangile

=item * vendredi saint

=item * Lundi de Pâques

=item * 1er mai : Fête du travail

=item * 8 mai : Armistice 39-45

=item * Ascension

=item * Lundi de Pentecôte

=item * 29 juin : fête de l'autonomie

=item * 14 juillet : Fête nationale

=item * 15 août : Assomption

=item * 1er novembre : Toussaint

=item * 11 novembre : Armistice 14-18

=item * 25 décembre : Noël

=back

Easter is computed with Date::Easter module.

Vendredi saint is 2 days before easter

Ascension is 39 days after easter.

Pentecost is 50 days after easter.

=head1 SUBROUTINES

=head2 is_pf_holiday($year, $month, $day)

Returns the name of the holiday in french polynesia that falls on the given day, or undef
if there is none.

=head2 get_easter($year)

Returns the month and day of easter day for the given year.

=head2 get_vendredisaint($year)

Returns the month and day of vendredi saint day for the given year.

=head2 get_ascension($year)

Returns the month and day of ascension day for the given year.

=head2 get_pentecost($year)

Returns the month and day of pentecost day for the given year.

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system 
at http://rt.cpan.org/ or email to bug-Date-Holidays-PF\@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-PF is the RT queue for Date::Holidays::PF.
Please check to see if your bug has already been reported. 

=head1 COPYRIGHT

Copyright 2017

Dominix dominix@cpan.org based on Date::Holidays::FR by Fabien Potencier, fabpot@cpan.org

This software may be freely copied and distributed under the same
terms and conditions as Perl.

=head1 SEE ALSO

perl(1), Date::Holidays::UK, Date::Holidays::FR.

=cut

package Date::Holidays::PT;

use warnings;
use strict;

use utf8;
use Date::Holidays::Super;
use Date::Easter;
use Time::JulianDay;

my @ISA = qw(Date::Holidays::Super);

=encoding utf-8

=head1 NAME

Date::Holidays::PT - Determine Portuguese public holidays

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Date::Holidays::PT;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  print "Woohoo" if is_pt_holiday( $year, $month, $day );

  my $h = pt_holidays($year);
  printf "Jan. 1st is named '%s'\n", $h->{'0101'};

=head1 FUNCTIONS

=head2 new

Creates a new Date::Holidays::PT object.

  my $mh = Date::Holidays::PT->new();

=cut

sub new {
  my $self = shift;
  bless \$self => $self;
}

=head2 is_holiday

Should at least take three arguments:

year  (four digits)
month (between 1-12)
day   (between 1-31)

The return value from is_holiday is either a 1 or a 0 (1 if the
specified date is a holiday, 0 otherwise).

  if ( $mh->is_holiday( $year, $month, $day ) ) {
    # it's a holiday
  }

=cut

sub is_holiday {
  my $self = shift;
  return $self->is_pt_holiday(@_);
}

=head2 is_pt_holiday

Similar to is_holiday, but instead of returning 1 if the date is a
holiday returns a string comprising the name of the holidays. In the
event of two or more holidays on the same day (hey, it happens), the
string will comprise the name of all those holidays separated by a
semicolon.

  my $todays_holiday = $mh->is_pt_holiday( $year, $month, $day );
  if ( $todays_holiday ) {
    print "Today is $todays_holiday.\nDon't bother getting up!\n";
  }

=cut

sub is_pt_holiday {
  my $self = shift;
  my ($year, $month, $day) = @_;
  defined $year  || return undef;
  defined $month || return undef;
  defined $day   || return undef;

  my $holidays = $self->holidays($year);
  if (defined $holidays->{$month} and defined $holidays->{$month}{$day}) {
    return $holidays->{$month}{$day};
  }
  else {
    return undef;
  }

}

=head2 holidays

Should take at least one argument:

year  (four digits)

Returns a reference to a hash, where the keys are date represented as
four digits, the two first representing month (01-12) and the last two
representing day (01-31).

The value for the key in question is the local name for the holiday
indicated by the day. In the event of two or more holidays on the same
day (yes, it happens!), the values will comprise the name of all those
holidays separated by a semicolon.

  my $years_holidays = holidays( $year );
  for (keys %$years_holidays) {
    my ($day, $month) = /(..)(..)/;
    print "$day/$month - $years_holidays->$_\n";
  }

=cut

sub holidays {
  my $self = shift;
  my $year = shift;
  defined $year || return undef;

  my %holidays = (
       1 => {
          1 => 'Ano Novo',
       },
       4 => {
         25 => 'Dia da Liberdade',
       },
       5 => {
          1 => 'Dia do Trabalhador',
       },
       6 => {
         10 => 'Dia de Portugal, de Camões e das Comunidades',
       },
       8 => {
         15 => 'Assunção de Nossa Senhora',
       },
      10 => {
          ($year <= 2012) ? (5 => 'Dia da Implantação da República') : (),
       },
      11 => {
          ($year <= 2012) ? (1 => 'Dia de Todos-os-Santos') : (),
       },
      12 => {
		  ($year <= 2012) ? (1 => 'Dia da Restauração da Independência') : (),
          8 => 'Imaculada Conceição',
         25 => 'Natal',
       },
  );

  my ($emonth, $eday) = gregorian_easter($year);
  $holidays{$emonth}{$eday} = 'Páscoa';

  my $jd = julian_day($year, $emonth, $eday);

  if ($year <= 2012) {
	  my (undef, $cmonth, $cday) = inverse_julian_day($jd - 47);
	  $holidays{$cmonth}{$cday} = 'Entrudo';

	  my (undef, $bmonth, $bday) = inverse_julian_day($jd + 60);
	  $holidays{$bmonth}{$bday} =
	             $holidays{$bmonth}{$bday} ?
	            $holidays{$bmonth}{$bday} . '; Corpo de Deus':
	           'Corpo de Deus';
   }

  my (undef, $smonth, $sday) = inverse_julian_day($jd - 2);
  $holidays{$smonth}{$sday} = 'Sexta-feira Santa';

  return \%holidays;
}

=head1 NATIONAL HOLIDAYS

The following Portuguese holidays have fixed dates:

    Jan   1    Ano Novo
    Apr  25    Dia da Liberdade
    May   1    Dia do Trabalhador
    Jun  10    Dia de Portugal, de Camões e das Comunidades
    Aug  15    Assunção da Virgem
    Oct   5    Dia da Implantação da República
    Nov   1    Dia de Todos-os-Santos
       -- no longer holiday, maintained for completude
    Dec   1    Dia da Restauração da Independência
       -- no longer holiday, maintained for completude
    Dec   8    Imaculada Conceição
    Dec  25    Natal

The following Portuguese holidays have mobile dates:

    Entrudo (47 days before Páscoa / Easter)
       -- no longer holiday, maintained for completude
    Sexta-feira Santa (Friday before Páscoa / Easter)
    Páscoa (Easter)
    Corpo de Deus (60 days after Páscoa / Easter)
       -- no longer holiday, maintained for completude

=head1 ACKNOWLEDGEMENTS

Paulo Rocha, for all his knowledge about holidays and everything else.

Jonas B. Nielsen, for his work regarding the standardization of
Date::Holidays modules.

=head1 AUTHOR

José Castro, C<< <cog@cpan.org> >>

Maintained by Alberto Simões, C<< <ambs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-date-holidays-pt@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2015 José Castro, All Rights Reserved.
Copyright 2005 Alberto Simões, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of Date::Holidays::PT

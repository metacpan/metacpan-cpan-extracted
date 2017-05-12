package Date::Holidays::BR;

use warnings;
use strict;

use Date::Holidays::Super;
use Date::Easter;
use Time::JulianDay;

my @ISA = qw(Date::Holidays::Super);

=head1 NAME

Date::Holidays::BR - Determine Brazilian public holidays

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Date::Holidays::BR;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  print "Woohoo" if is_br_holiday( $year, $month, $day );

  my $h = br_holidays($year);
  printf "Jan. 1st is named '%s'\n", $h->{'0101'};

=head1 FUNCTIONS

=head2 new

Creates a new Date::Holidays::BR object.

  my $mh = Date::Holidays::BR->new();

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
  return $self->is_br_holiday(@_);
}

=head2 is_br_holiday

Similar to is_holiday, but instead of returning 1 if the date is a
holiday returns a string comprising the name of the holidays. In the
event of two or more holidays on the same day (hey, it happens), the
string will comprise the name of all those holidays separated by a
semicolon.

  my $todays_holiday = $mh->is_br_holiday( $year, $month, $day );
  if ( $todays_holiday ) {
    print "Today is $todays_holiday.\nDon't bother getting up!\n";
  }

=cut

sub is_br_holiday {
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
          1 => 'Confraternização Universal',
       },
       4 => {
         21 => 'Tiradentes',
       },
       5 => {
          1 => 'Dia do Trabalho',
       },
       9 => {
          7 => 'Independência do Brasil',
       },
      10 => {
         12 => 'Nossa Senhora Aparecida',
       },
      11 => {
          2 => 'Dia de Finados',
         15 => 'Proclamação da República',
       },
      12 => {
         25 => 'Natal',
       },
  );

  my ($emonth, $eday) = gregorian_easter($year);
#  $holidays{$emonth}{$eday} = 'Páscoa';

  my $jd = julian_day($year, $emonth, $eday);

  my (undef, $smonth, $sday) = inverse_julian_day($jd - 2);
  $holidays{$smonth}{$sday} = 'Sexta-feira da Paixão';

  return \%holidays;
}

42;
__END__
=head1 NATIONAL HOLIDAYS

The following Brazilian holidays have fixed dates:

    Jan   1    Confraternização Universal
    Apr  21    Tiradentes
    May   1    Dia do Trabalho
    Sep   7    Independência do Brasil
    Oct  12    Nossa Senhora Aparecida
    Nov   2    Dia de Finados
    Nov  15    Proclamação da República
    Dec  25    Natal

The following Brazilian holidays have mobile dates:

    Sexta-feira da Paixão (Friday before Páscoa / Easter)

=head1 ABOUT BRAZILIAN HOLIDAYS

Being a large country, Brazil separates its holidays in national, state and 
municipal holidays. Law 9.093 of 1995 states as holidays:

=over 4

=item * the B<fixed> dates above;

=item * the I<< data magna >> of the State (State's most important date, as 
determined in that State's law);

=item * the days beginning and ending the hundredth year of a city's 
foundation, as determined in that City's law);

=item * religious holidays as determined by each City's law, no more than 4, and
already including I<< Sexta-feira da Paixão >>.

=back

Since that last item makes I<< Sexta-feira da Paixão >> a holiday for every city 
in the Country, it was marked as a national holiday.

Páscoa (Easter) is celebrated, but since it always falls on a Sunday, there is 
no law declaring it as an actual Brazilian Holiday. If you feel it should be 
added or finds out I am mistaken, please let me know.

=head1 SEE ALSO

L<< Lei 10.607 de 2002|http://www.planalto.gov.br/CCIVIL/leis/2002/L10607.htm >>

L<< Lei 9.335 de 1996|http://www.planalto.gov.br/ccivil_03/Leis/L9335.htm >>

L<< Lei 9.093 de 1995|http://www.planalto.gov.br/ccivil_03/Leis/L9093.htm >>

L<< Lei 6.802 de 1980|http://www.planalto.gov.br/ccivil_03/Leis/L6802.htm >>

L<< Lei 662 de 1949|http://www.planalto.gov.br/CCIVIL/leis/L0662.htm >>

=head1 ACKNOWLEDGEMENTS

Jonas B. Nielsen, for his work regarding the standardization of
Date::Holidays modules.

Jose Castro, as this module was taken nearly verbatim from 
L<< Date::Duration::PT >>.

=head1 AUTHOR

Breno G. de Oliveira, C<< <garu@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-date-holidays-br@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Breno G. de Oliveira, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

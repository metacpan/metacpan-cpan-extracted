package Date::Holidays::ES;
use base 'Date::Holidays::Super';
use warnings;
use strict;

use Date::Easter ();
use Time::JulianDay ();
use Carp qw(croak);

our $VERSION = '0.02';


sub new {
    my $class = shift;
    return bless \$class, $class;
}

sub is_holiday {
    my ($self, %params) = @_;
    my $year  = $params{'year'}  or croak 'Missing year argument';
    my $month = $params{'month'} or croak 'Missing month argument';
    my $day   = $params{'day'}   or croak 'Missing day argument';

    my $holidays = $self->holidays(year => $year);

    my $month_day = sprintf "%02d%02d", $month, $day;

    if (exists $holidays->{$month_day}) {
        return $holidays->{$month_day};
    }

    return;
}

sub is_es_holiday {
    my $self = shift;
    return $self->is_holiday(@_);
}

sub holidays {
    my ($self, %params) = @_;
    my $year = $params{'year'} or croak 'Missing year argument';

    my $holidays = {
        '0101'  => 'Año Nuevo',
        #'0106'  => 'Día de Reyes',
        '0501'  => 'Día del Trabajo',
        '1012'  => 'Día de la Hispanidad',
        '1101'  => 'Día de Todos los Santos',
        '1206'  => 'Día de la Constitución',
        '1208'  => 'Día de la Inmaculada Concepción',
        '1225'  => 'Navidad',
    };

    my ($emonth, $eday) = Date::Easter::gregorian_easter($year);
    my $jd = Time::JulianDay::julian_day($year, $emonth, $eday);

    my (undef, $smonth, $sday) = Time::JulianDay::inverse_julian_day($jd - 2);
    my $month_day = sprintf "%02d%02d", $smonth, $sday;
    $holidays->{$month_day} = 'Viernes Santo';

    return $holidays;
}

sub es_holidays {
    my $self = shift;
    return $self->holidays(@_);
}

sub holidays_es {
    my ($self, %params) = @_;
    my $year = $params{'year'} or croak 'Missing year argument';

    my $holidays = $self->holidays(year => $year);
    my %hd = ();

    require DateTime;

    for my $month_day (keys %$holidays) {
        my ($month, $day) = unpack "A2A2", $month_day;
        $hd{ $holidays->{$month_day} } = DateTime->new(
            year  => $year,
            month => $month,
            day   => $day,
        );
    }

    return \%hd;
}

__END__

=head1 NAME

Date::Holidays::ES - Spanish holidays

=head1 SYNOPSIS

  use Date::Holidays;

  my $dh = Date::Holidays->new( countrycode => 'es' );

  print "Woohoo" if $dh->is_holiday( 
    year  => $year,
    month => $month,
    day   => $day
  );

  my $h = $dh->holidays( year => $year );
  printf "Jan. 1st is named '%s'\n", $h->{'0101'};

=head1 DESCRIPTION

This module provide the Spanish national holidays. You should use it with the
Date::Holidays OO wrapper, but you can also use it directly.

The following Spanish holidays have fixed dates:

  1  Jan           Año Nuevo
  1  May           Día del Trabajo
  12 Oct           Día de la Hispanidad
  1  Nov           Día de Todos los Santos
  6  Dec           Día de la Constitución
  8  Dec           Día de la Inmaculada Concepción
  25 Dec           Navidad

The following Spanish holiday hasn't a fixed date:

  Viernes Santo    Friday before Pascua / Easter

=head1 METHODS

=head2 new

Create a new Date::Holydays::ES object.

=head2 is_holiday

  if ( $dh->is_holiday( year => $year, month => $month, day => $day ) ) {
    # it's a holiday
  }

Arguments:

  year  (four digits)
  month (between 1-12)
  day   (between 1-31)

The return value from is_holiday is either the string with the holiday name or
an undefined value.

=head2 is_es_holiday

A wrapper of the L<is_holiday> method. Not available through
L<Date::Holidays>.

=head2 holidays

  my $yh = $dh->holidays( year => $year );

  for (keys %$yh) {
    my ($day, $month) = unpack "A2A2", $_;
    print "$day/$month - $yh->{$_}\n";
  }

Arguments:

  year  (four digits)

Returns a hash reference, where the keys are dates represented as
four digits, the two first representing the month (01-12) and the last two
representing the day (01-31).

The value for a given key is the local name for the holiday.

=head2 es_holidays

A wrapper of the L<holidays> function. Not available through
L<Date::Holidays>.

=head2 holidays_es

  my $dh = Date::Holidays::ES->new;
  my $yho = $dh->holidays_es( year => $year );

  for my $holiday (sort keys %$yho) {
     my $dt    = $yho->{$holiday};
     my $year  = $dt->year;
     my $month = $dt->month;
     my $day   = $dt->day;
     print "$holiday is on $day/$month/$year\n"; 
  }

Arguments:

  year  (four digits)

This method is not available through L<Date::Holidays>' interface.

Returns a hash reference, where the keys are the holidays name and the values
are L<DateTime> objects.

=head1 SEE ALSO

L<Date::Holidays>, L<DateTime> 

=head1 AUTHOR

Florian Merges, E<lt>fmerges@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Florian Merges, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

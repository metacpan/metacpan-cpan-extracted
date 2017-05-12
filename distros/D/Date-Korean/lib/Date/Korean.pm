package Date::Korean;

use strict;
use warnings;
use version; our $VERSION = qv('0.0.2');
use base 'Exporter';
use DateTime;
use DateTime::Calendar::Julian;
use Date::ISO8601 qw/cjdn_to_ymd/;
use Date::Korean::Table;
use Carp;

our @EXPORT = qw/get_ganzi get_ganzi_ko sol2lun lun2sol/;

sub _calculate_ganzi {
    my($year,$month,$day,$leap) = @_;

    my @ganzis = ( ($year+56)%60, ($year*12+$month+13)%60 );
    ($year,$month,$day) = lun2sol($year,$month,$day,$leap);
    # mjd(Modified Julian Date)
    my $mjd = DateTime->new(year=>$year,month=>$month,day=>$day)->mjd;
    # solar 1582-10-15 -> mjd:-100840
    if ($mjd < -100840) { 
        $mjd += DateTime::Calendar::Julian
                ->new(year=>$year,month=>$month,day=>$day)
                ->gregorian_deviation;
    }
    push @ganzis, ($mjd+50)%60;
    return @ganzis;
}

sub get_ganzi {
    return map { $CELESTIAL_STEMS[$_%10].$TERRESTRIAL_BRANCHES[$_%12] }
           _calculate_ganzi(@_);
}

sub get_ganzi_ko {
    return map { $CELESTIAL_STEMS_KO[$_%10].$TERRESTRIAL_BRANCHES_KO[$_%12] }
           _calculate_ganzi(@_);
}

sub sol2lun {

    my($year,$month,$day) = @_;

    my $days;
    eval {
        # Chronological Julian Day(cjd)
        $days = DateTime->new(year=>$year,month=>$month,day=>$day)->jd+0.5;
    };
    if ($@) { # Maybe valid Julian date.
        if ( $year<=1582 ) {
            eval { 
                $days = DateTime::Calendar::Julian
                        ->new(year=>$year,month=>$month,day=>$day)->jd+0.5;
            };
            if ($@) {
                croak "Invalid date.";
            }
        }
        else {
            croak "Invalid date.";
        }
    }
    # solar 1582-10-15 -> cjd:2299161 ,After this are gregorian calendar range.
    if ( $days < 2299161 ) {  # julian calendar range
        # gregorian 1582-10~05 ~ 1582-10-14 dates do not exist.
        if ( $year==1582 && $month==10 && $day>=5 && $day<=14) {
            croak "The gregorian date does not exist\n";
        }
        $days = DateTime::Calendar::Julian
                ->new(year=>$year,month=>$month,day=>$day)->jd+0.5;
    }

    if ( $days<$MINDATE || $days>$MAXDATE ) {
        croak "The date is out of range."
    }

    $days -= $MINDATE;
    $month = _bisect(\@MONTHTABLE,$days);
    $year = _bisect(\@YEARTABLE,$month);
    ($month,$day) = ( $month-$YEARTABLE[$year]+1, $days-$MONTHTABLE[$month]+1);
    my $leap;
    if ( $LEAPTABLE[$year]!=0 && $LEAPTABLE[$year]<=$month ) {
        if ( $LEAPTABLE[$year] == $month ) {
            $leap = 1;
        }
        else {
            $leap = 0;
        }
        $month -= 1;
    }
    else {
        $leap = 0;
    }

    return ( $year+$BASEYEAR, $month, $day, $leap );
}

sub lun2sol {

    my($year,$month,$day,$leap) = @_;

    $year -= $BASEYEAR;

    unless ( $year>=0 && $year< $#YEARTABLE ) {
        croak "Year is out of range.";
    }

    unless ( $month>=1 && $month <=12 ) {
        croak "Month is out of range.";
    }

    if ( $leap!=0 && ($LEAPTABLE[$year]-1)!=$month ) {
        croak "Wrong leap month.";
    }

    my $months = $YEARTABLE[$year] + $month - 1;

    if ( $leap==1 && ($month+1)==$LEAPTABLE[$year] ) {
        $months += 1;
    }
    elsif ( $LEAPTABLE[$year]!=0 && $LEAPTABLE[$year]<=$month ) {
        $months += 1;
    }

    my $days = $MONTHTABLE[$months] + $day -1;

    if ( $day<1 || $days>=$MONTHTABLE[$months+1]) {
        croak "Wrong day.";
    }

    # 1582-10-15 -> cjd(chronical julian date):2299161
    if ( ($days+$MINDATE) < 2299161 ) {
        my ($y,$m,$d) = cjdn_to_ymd($days+$MINDATE);
        my $deviation = DateTime::Calendar::Julian
                        ->new(year=>$y,month=>$m,day=>$d)
                        ->gregorian_deviation;
        return cjdn_to_ymd($days+$MINDATE-$deviation);
    }
    else {
        return cjdn_to_ymd($days+$MINDATE);
    }
}

sub _bisect {
    my ($a,$x) = @_;
    my $lo = 0;
    my $hi = $#{$a};
    while ( $lo < $hi ) {
        my $mid = int( ($lo+$hi)/2 );
        if ( $x < $a->[$mid] ) {
            $hi = $mid;
        }
        else {
            $lo = $mid + 1;
        }
    }

    return $lo-1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Date::Korean - Conversion between Korean solar / lunisolar date.

=head1 SYNOPSIS

    use Date::Korean;

    # convert solar to lunisolar date
    my ($ly, $lm, $ld, $leap) = sol2lun(2008, 10, 10);

    # convert lunisolar to solar date
    my ($sy, $sm, $sd) = lun2sol(2008, 9, 12, 0);

    # get ganzi in chinese
    my ($saecha, $wolgun, $iljin) = get_ganzi(2008, 9, 12, 0);

    # get ganzi in korean
    my ($saecha, $wolgun, $iljin) = get_ganzi_ko(2008, 9, 12, 0);

=head1 DESCRIPTION

The traditional korean lunisolar calendar is based on the chinese calendar. This module handles conversion between Korean solar and lunisolar date.

=head1 FUNCTIONS

=over 4

=item sol2lun

  my ($ly, $lm, $ld, $leap) = sol2lun(2008, 10, 10);

Convert solar to lunisolar date. This function takes solar year, month, day arguements and returns lunisolar year, month, day and leap flag( 1 if month is leap month, or 0 if not )

=item lun2sol

 my ($sy, $sm, $sd) = lun2sol(2008, 9, 12, 0);

Convert lunisolar to solar date. This function takes lunisolar year, month, day, leap flag and returns solar year, month, day.

=item get_ganzi

 my ($saecha, $wolgun, $iljin) = get_ganzi(2008, 9, 12, 0);
 binmode STDOUT, ':encoding(UTF-8)';
 print "$saecha $wolgun $iljin\n";

output

 戊子 壬戌 癸未

Get ganzi (sexagenary cycle - 干支) of year(歲次), month(月建), day(日辰) in chinese. This function takes lunisolar year, month, day, leap flag.

=item get_ganzi_ko

 my ($saecha, $wolgun, $iljin) = get_ganzi_ko(2008, 9, 12, 0);
 binmode STDOUT, ':encoding(UTF-8)';
 print "$saecha $wolgun $iljin\n";

output

 무자 임술 계미

Get ganzi (sexagenary cycle - 간지) of year(세차), month(월건), day(일진) in korean. This function takes lunisolar year, month, day, leap flag.

=back

=head1 CAVEATS

=over 4

=item *

Conversion between solar and lunisolar date is very difficult because it based on complicated astronomical calculation. Parameters of the conversion equation are sometimes not constant and should be obtained from astronomical observation. So I used precalculated conversion table because the calculation result does not fully gurantee the accuracy of it.

=item *

Conversion table was striped and generated from solar <-> lunisolar conversion service on Korea Astronomy & Space Science Institute ( http://www.kao.re.kr/ ). Currently supported date range is from solar 1391-02-05 ( lunisolar 1391-01-01 ) to 2050-12-31 ( lunisolar 2050-11-18 ).

=back

=head1 AUTHOR

C.H. Kang E<lt>chahkang_AT_gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>, L<DateTime::Calendar::Julian>, L<Date::ISO8601>

=cut


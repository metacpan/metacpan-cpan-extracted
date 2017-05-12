package Calendar::Any::Util::Calendar;
{
  $Calendar::Any::Util::Calendar::VERSION = '0.5';
}
use Calendar::Any;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
calendar $week_start_day
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $week_start_day = 0;

sub calendar {
    my ($month, $year, $package) = @_;
    if ( defined($package) && $package =~ /China|Chinese/) {
        chinese_simple($month, $year);
    } else {
        generic_simple(@_);
    }
}

sub generic_simple {
    my ($month, $year) = @_;
    my @month = generic_calendar(@_);
    my $cal = "$Calendar::Any::month_name[$month-1] $year\n\n";
    $cal .= join(" ", map {
        substr($Calendar::Any::weekday_name[$_], 0, 2)
    } $week_start_day..6, 0..($week_start_day-1) ). "\n";
    $cal .= join("\n", map {
        join(" ", map { $_ ? sprintf "%2d", $_ : '  ' } @$_);
    } @month);
    return $cal;
}

sub generic_calendar {
    my ($month, $year, $package) = @_;
    defined($package) || ($package = "Gregorian");
    my $module = "Calendar::Any::$package";
    eval("require $module");
    if ( $@ ) {
        die "Can't load module $module: $@!\n"
    }
    my $start = $module->new(-month => $month, -day => 1, -year => $year);
    my $weekday = ($start->weekday-$week_start_day) % 7;
    my $last = $start->last_day_of_month;
    my @month = ((undef)x$weekday, 1..$last, (undef)x ( 7 - (($weekday+$last)%7  || 7) ));
    return map { [@month[$_*7..$_*7+6]] } 0..(@month/7-1);
}

sub chinese_simple {
    my ($month, $year) = @_;
    my ($months, $newmonth) = chinese_calendar(@_);
    # print it
    my $cal = center_han_string(
        sprintf("%d年%d月  %s年%s", $year, $month,
                      $newmonth->[-1][1]->sexagesimal_name,
                      join("，", map { sprintf "%s%s%d日始", $_->[1]->month_name(),
                                           ($_->[1]->last_day_of_month > 29 ? "大" : "小"),
                                               $_->[0] } @$newmonth)),
        9*7-3) . "\n";
    $cal .= join("   ", map {
        substr($Calendar::Any::weekday_name[$_], 0, 3) . " " . $Calendar::Any::Chinese::weekday_name[$_]
    } $week_start_day..6, 0..($week_start_day-1)) . "\n";
    foreach ( @$months ) {
        foreach ( @$_) {
            my $str;
            if ( $_ ) {
                $str = sprintf("%2d", $_->[0]);
                my $cdate = $_->[1];
                if ( exists $cdate->{jieqi} ) {
                    $str .= $Calendar::Any::Chinese::jieqi_name[$cdate->{jieqi}].' ' x 2;
                } elsif ( $cdate->day == 1 ) {
                    # make sure the month name is less than 3 character. the only
                    # exception is '闰十一月'
                    my $month_name = $cdate->month_name;
                    Encode::_utf8_on($month_name);
                    if (length($month_name) >= 3) {
                        $month_name = substr($month_name, 0, 3);
                    } else {
                        $month_name .= "  ";
                    }
                    Encode::_utf8_off($month_name);
                    $str .= $month_name;
                } else {
                    $str .= $cdate->day_name.' 'x2;
                }
            } else {
                $str = ' ' x 8;
            }
            $cal .= $str . " ";
        }
        $cal .= "\n";
    }
    return $cal;
}

sub chinese_calendar {
    require Encode;
    require Calendar::Any::Chinese;
    my ($month, $year) = @_;
    unless ( $month=~ /^\d+$/ && $year =~ /^\d+$/ && $month>0 && $month<13 ) {
        pod2usage();
    }
    my $tz = Calendar::Any::Chinese::timezone($year);
    my $start = Calendar::Any->new_from_Gregorian($month, 1, $year); # first date of Gregorian
    my $weekday = ($start->weekday - $week_start_day) % 7; # weekday of first date
    my $last = $start->last_day_of_month; # last day of this month
    my @month = ((undef)x$weekday, 1..$last, (undef)x ( 7 - (($weekday+$last)%7  || 7) ));
    my $adate = $start->absolute_date-1;
    my @newmonth;
    foreach ( $weekday..$#month ) {
        last unless defined $month[$_];
        my $cdate = Calendar::Any::Chinese->new($adate+$month[$_]);
        $month[$_] = [$month[$_], $cdate];
        push @newmonth, $month[$_] if $cdate->day == 1;
    }
    $start = $month[$weekday]->[1];
    # mark up jieqi
    my $first_jieqi = Calendar::Any::Chinese::next_jieqi_date($adate, $tz);
    my $second_jieqi = Calendar::Any::Chinese::next_jieqi_date($first_jieqi+1, $tz);
    $adate++;
    $month[$first_jieqi-$adate+$weekday]->[1]->{jieqi}=2*($month-1);
    $month[$second_jieqi-$adate+$weekday]->[1]->{jieqi}=2*$month-1;
    return ([map { [ @month[$_*7..$_*7+6]] } 0..(@month/7-1)], \@newmonth);
}

sub center_han_string {
    require Encode;
    my ($str, $len) = @_;
    my $enc = $str;
    Encode::_utf8_on($enc);
    $enc = Encode::encode('cp936', $enc);
    my $pad = ($len-length($enc))/2;
    return ' ' x $pad . $str . ' ' x $pad;
}

1;

__END__

=head1 NAME

Calendar::Any::Util::Calendar - A collection of function for create calendars

=head1 VERSION

version 0.5

=head1 SYNOPSIS

     use Calendar::Any::Util::Calendar qw(calendar);
     print calendar(12, 2006), "\n";

=head1 DESCRIPTION

A very simple module that output various calendars.

=over

=item calendar(month, year, [package])

Output the calendar for the month in the year. If given package,
output the calendar of the package. For example: 

     print calendar(12, 2006, 'Julian'), "\n";

This will output calendar in Julian calendar.

=item  generic_calendar(month, year, [package])

Return an array of dates in the month break by weekday:

    ( [ undef, undef, undef, undef, undef, 1, 2 ],
      [ 3, 4, 5, 6, 7, 8, 9 ],
      [ 10, 11, 12, 13, 14, 15, 16 ],
      [ 17, 18, 19, 20, 21, 22, 23 ],
      [ 24, 25, 26, 27, 28, 29, 30 ],
      [ 31, undef, undef, undef, undef, undef, undef ] )

The default week start day is Sunday. If you want start from Monday,
set $week_start_day to 1.

=item chinese_calendar($month, $year)

The difference between the generic_calendar is the return array,
contain not only the day of the month, but also the Calendar::China
date. And to address the start date of the new chinese month, the
return value of the function contain two elements, one is the month
calendar array, which like:

    [ [ undef, undef, undef, undef, undef, [1, D], [2, D] ],
        ...
      [ [31, D], undef, undef, undef, undef, undef, undef ] ]

The D stands for Calendar::China date. The second element is an array
of new chinese month date. A month may contain two new chinese month
date. 

=back

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 by ywb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

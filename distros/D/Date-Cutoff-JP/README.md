[![Build Status](https://travis-ci.com/worthmine/Date-Cutoff-JP.svg?branch=main)](https://travis-ci.com/worthmine/Date-Cutoff-JP) [![MetaCPAN Release](https://badge.fury.io/pl/Date-Cutoff-JP.svg)](https://metacpan.org/release/Date-Cutoff-JP)
# NAME

Date::CutOff::JP - Get the day cutoff and payday for in Japanese timezone

# SYNOPSIS

    use Date::CutOff::JP;
    my $dco = Date::CutOff::JP->new({ cutoff => 0, late => 1, payday => 0 });
    my %calculated = $dco->calc_date('2019-01-01');
    print $calculated{'cutoff'}; # '2019-01-31'
    print $calculated{'payday'}; # '2019-02-28'

# DESCRIPTION

Date::CutOff::JP provides how to calculate the day cutoff and the payday from Japanese calendar.

You can calculate the weekday for cutoff and paying without holidays in Japan.

# Constructor

### new({ \[cutoff => $day\], \[payday => $day\], \[late => 0||1||2\] })

You may omit parameters. defaults are { cutoff => 0, payday => 0, late => 1 }

## Accessor Methods

### cutoff()

get/set the day cutoff in every months. 0 means the end of the month.

**caution** Int over 28 is denied

### payday()

get/set the payday in every months. 0 means the end of the month.

**caution** Int over 28 is denied

### late()

get/set the lateness. 0 means the cutoff and payday is at same month.

The all you can set is Int of \[ 0 .. 2 \] 3 or more returns error.

## Method

### calc\_date(\[$date\])

You may omit the parameter. default is TODAY.

returns hash value with keys below:

- cutoff

    The latest cutoff after $date.

- payday

    The latest payday after $date.

- is\_over ( maybe bad key name )

    Is or not that the cutoff is pending until next month.

# BUGS

# SEE ALSO

[Calendar::Japanese::Holiday](https://metacpan.org/pod/Calendar%3A%3AJapanese%3A%3AHoliday),[Date::DayOfWeek](https://metacpan.org/pod/Date%3A%3ADayOfWeek)

[日本の祝日YAML](https://github.com/holiday-jp/holiday_jp/blob/master/holidays.yml)

# LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

worthmine <worthmine@cpan.org>

# NAME

DateTime::Schedule - Determine scheduled days in range based on exclusions

# SYNOPSIS

    use DateTime::Schedule;

    my $dts = DateTime::Schedule->new(exclude => [
      DateTime->new(year => 2024, month => 01, day => 01),
      DateTime->new(year => 2024, month => 07, day => 04),
      DateTime->new(year => 2024, month => 12, day => 25)
    ]);

    my $start = DateTime->new(year => 2024, month => 1, day => 1);
    my $end = DateTime->new(year => 2024, month => 12, day => 31);
    print $dts->days_in_range($start, $end)->count; # 363

# DESCRIPTION

This is a simple class that allows you to find out which days are "scheduled"
between a start date and an end date. For instance, given the start date of a
school year, and the current date, and with all school holidays entered as 
["exclude"](#exclude)d, this can tell you how many school days have elapsed in the year.

# CONSTRUCTORS

## new

Default constructor. Returns a new [DateTime::Schedule](https://metacpan.org/pod/DateTime%3A%3ASchedule) instance.

Parameters:

#### portion

_Optional_. Default `1`.

A number between 0 and 1 indicating how much of a day must elapse to be
included/excluded at the boundaries of the range.

#### exclude

_Optional_. Default `[]`

An arrayref of [DateTime](https://metacpan.org/pod/DateTime)s. These days are exclusions to the normal schedule
(e.g., holidays). Any time-portion of the DateTimes is ignored.

# METHODS

## days\_in\_range($start, $end)

Given start/end [DateTime](https://metacpan.org/pod/DateTime)s, returns a [DateTime::Set](https://metacpan.org/pod/DateTime%3A%3ASet) of all the days which
are scheduled (i.e., not excluded)

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# NAME

Date::Lectionary - Readings for the Christian Lectionary

# VERSION

Version 1.20200203

# SYNOPSIS

    use Time::Piece;
    use Date::Lectionary;

    my $epiphany = Date::Lectionary->new('date'=>Time::Piece->strptime("2017-01-06", "%Y-%m-%d"));
    say $epiphany->day->name; #String representation of the name of the day in the liturgical calendar; e.g. 'The Epiphany'
    say $epiphany->year->name; #String representation of the name of the liturgical year; e.g. 'A'
    say ${$epiphany->readings}[0] #String representation of the first reading for the day.

# DESCRIPTION

Date::Lectionary takes a Time::Piece date and returns the liturgical day and associated readings for the day.

## ATTRIBUTES

### date

The Time::Piece object date given at object construction.

### lectionary

An optional attribute given at object creation time.  Valid values are 'acna' for the Anglican Church of North America lectionary and 'rcl' for the Revised Common Lectionary with complementary readings in ordinary time.  This attribute defaults to 'acna' if no value is given.

### day

A Date::Lectionary::Day object containing attributes related to the liturgical day.

`type`: Stores the type of liturgical day. 'fixedFeast' is returned for non-moveable feast days such as Christmas Day. 'moveableFeast' is returned for moveable feast days.  Moveable feasts move to a Monday when they occure on a Sunday. 'Sunday' is returned for non-fixed feast Sundays of the liturgical year.  'noLect' is returned for days with no feast day or Sunday readings.

`name`: The name of the day in the lectionary.  For noLect days a String representation of the day is returned as the name.

`alt`: The alternative name --- if one is given --- of the day in the lectionary.  If there is no alternative name for the day, then the empty string will be returned.

`multiLect`: Returns 'yes' if the day has multiple services with readings associated with it.  (E.g. Christmas Day, Easter, etc.)  Returns 'no' if the day is a normal lectioanry day with only one service and one set of readings.

### year

A Date::Lectionary::Year object containing attributes related to the liturgical year the date given at object construction resides in.

`name`: Returns 'A', 'B', or 'C' depending on the liturgical year the date given at object construction resides in.

### readings

Return an ArrayRef of the String representation of the day's readings if there are any.  Readings in the ArrayRef are ordered in the array according to the order the readings are given in the lectionary.  If mutliple readings exist for the day, an ArrayRef of HashRefs will be given.

    my $singleReading = Date::Lectionary->new(
        'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
        'lectionary' => 'acna'
    );

    say ${ $testReading->readings }[1]; #Will print 'Ps 98', the second reading for the Sunday closest to November 16 in the default ACNA lectionary for year C.
    say $testReading->day->multiLect; #Will print 'no' because this day does not have multiple services in the lectionary.

    my $multiReading = Date::Lectionary->new(
        'date'       => Time::Piece->strptime( "2016-12-25", "%Y-%m-%d" ),
        'lectionary' => 'rcl'
    );

    say $multiReading->day->multiLect; #Will print 'yes' because this day does have multiple services in the lectionary.
    say ${ $multiReading->readings }[0]{name}; #Will print 'Christmas, Proper I', the first services of Christmas Day in the RCL
    say ${ $multiReading->readings }[1]{readings}[0]; #Will print 'Isaiah 62:6-12', the first reading of the second service 'Christmas, Proper II' on Christmas Day in the RCL.

# SUBROUTINES/METHODS

## BUILD

Constructor for the Date::Lectionary object.  Takes a Time::Piect object, `date`, to create the object.

## \_buildMultiReadings

Private method that returns an ArrayRef of HashRefs for the multiple services and lectionary readings associated with the date.

## \_buildReadings

Private method that returns an ArrayRef of strings for the lectionary readings associated with the date.

## \_determineAdvent

Private method that takes a Time::Piece date object to returns a Date::Advent object containing the dates for Advent of the current liturgical year.

# AUTHOR

Michael Wayne Arnold, `<michael at rnold.info>`

# BUGS

<div>
    <a href="https://travis-ci.org/marmanold/Date-Lectionary"><img src="https://travis-ci.org/marmanold/Date-Lectionary.svg?branch=master"></a>
</div>

<div>
    <a href='https://coveralls.io/github/marmanold/Date-Lectionary?branch=master'><img src='https://coveralls.io/repos/github/marmanold/Date-Lectionary/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

Please report any bugs or feature requests to `bug-date-lectionary at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Lectionary

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Date-Lectionary](http://annocpan.org/dist/Date-Lectionary)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Date-Lectionary](http://cpanratings.perl.org/d/Date-Lectionary)

- Search CPAN

    [http://search.cpan.org/dist/Date-Lectionary/](http://search.cpan.org/dist/Date-Lectionary/)

# ACKNOWLEDGEMENTS

Many thanks to my beautiful wife, Jennifer, my amazing daughter, Rosemary, and my sweet son, Oliver.  But, above all, SOLI DEO GLORIA!

# LICENSE

Copyright 2016-2020 MICHAEL WAYNE ARNOLD

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1\. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2\. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

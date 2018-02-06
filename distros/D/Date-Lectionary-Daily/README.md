# NAME

Date::Lectionary::Daily - Daily Readings for the Christian Lectionary

# VERSION

Version 1.20180205

# SYNOPSIS

    use Time::Piece;
    use Date::Lectionary::Daily;

    my $dailyReading = Date::Lectionary::Daily->new('date' => Time::Piece->strptime("2017-12-24", "%Y-%m-%d"));
    say $dailyReading->readings->{evening}->{1}; #First lesson for evening prayer

# DESCRIPTION

Date::Lectionary::Daily takes a Time::Piece date and returns ACNA readings for morning and evening prayer for that date.

# SUBROUTINES/METHODS

## BUILD

Constructor for the Date::Lectionary object.  Takes a Time::Piect object, `date`, to create the object.

## \_parseLectDB

Private method to open and parse the lectionary XML to be used by other methods to XPATH queries.

## \_checkFixed

Private method to determine if the day given is a fixed holiday rather than a standard day.

## \_buildReadings

Private method that returns an ArrayRef of strings for the lectionary readings associated with the date.

# AUTHOR

Michael Wayne Arnold, `<marmanold at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-date-lectionary-daily at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary-Daily](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Lectionary-Daily).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Lectionary::Daily

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary-Daily](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Lectionary-Daily)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Date-Lectionary-Daily](http://annocpan.org/dist/Date-Lectionary-Daily)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Date-Lectionary-Daily](http://cpanratings.perl.org/d/Date-Lectionary-Daily)

- Search CPAN

    [http://search.cpan.org/dist/Date-Lectionary-Daily/](http://search.cpan.org/dist/Date-Lectionary-Daily/)

# ACKNOWLEDGEMENTS

Many thanks to my beautiful wife, Jennifer, and my amazing daughter, Rosemary.  But, above all, SOLI DEO GLORIA!

# LICENSE AND COPYRIGHT

Copyright 2017 MICHAEL WAYNE ARNOLD

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1\. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2\. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

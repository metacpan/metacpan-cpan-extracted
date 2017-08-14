# NAME

Date::Lectionary::Daily - Daily Readings for the Christian Lectionary

# VERSION

Version 1.20170809

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

Copyright 2017 Michael Wayne Arnold.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.

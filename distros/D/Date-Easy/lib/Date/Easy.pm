package Date::Easy;

use strict;
use warnings;
use autodie;

our $VERSION = '0.08'; # VERSION

use Date::Easy::Date ();
use Date::Easy::Datetime ();
use Date::Easy::Units ();

use Exporter;
use parent 'Exporter';
our @EXPORT = ( @Date::Easy::Date::EXPORT_OK, @Date::Easy::Datetime::EXPORT_OK, @Date::Easy::Units::EXPORT_OK, );


sub import
{
	Date::Easy::Date->import(':all');
	Date::Easy::Datetime->import(':all', @_[1..$#_]);
	Date::Easy::Units->import(':all');
	@_ = (shift);									# throw away all args except the first (package name)
	goto &Exporter::import;
}



1;



# ABSTRACT: easy dates with Time::Piece compatibility
# COPYRIGHT

__END__

=pod

=head1 NAME

Date::Easy - easy dates with Time::Piece compatibility

=head1 VERSION

This document describes version 0.08 of Date::Easy.

=head1 SYNOPSIS

    use Date::Easy


    # DATES

    # guaranteed to have a time of midnight
    my $d = date("3-Sep-1940");

    # addition and subtraction work in increments of days
    my $tomorrow = today + 1;
    my $last_week = today - 7;


    # DATETIMES

    # default timezone is your local zone
    my $dt = datetime("3/31/2012 7:38am");

    # addition and subtraction work in increments of seconds
    my $this_time_yesterday = now - 60*60*24;
    my $after_30_minutes = now + 30 * 60;

    # if you prefer UTC
    my $utc = datetime(UTC => "2016-03-07 01:22:16PST-0800");

    # or UTC for all your objects
    use Date::Easy 'UTC';
    say datetime("Jan 1 2000 midnight")->time_zone;
    # prints "UTC"


    # UNITS

    # basically just like the interface from Date::Piece
    say today + 3 * months;
    say now + 2 * hours - 5 * minutes;
    say 8 * weeks;
    # prints "8 weeks"

=head1 DESCRIPTION

Date::Easy provides simple date and datetime objects that will do what you expect, provided you
expect them to do the right things.  At its heart, a C<use Date::Easy> statement is just a shortcut
for this:

    use Date::Easy::Date ':all';
    use Date::Easy::Datetime ':all';
    use Date::Easy::Units ':all';

So, for full details, you should see the docs for L<Date::Easy::Date>, L<Date::Easy::Datetime> and
L<Date::Easy::Units>.  However, there are also a few parameters you can pass to Date::Easy (see
L</USAGE>).

=head2 Quick Start

A "datetime" (Date::Easy::Datetime) is an object which represents a date and time (internally, it's
just a L<Time::Piece> object, which is, at its heart, just a number of epoch seconds).  A "date"
(Date::Easy::Date) is just a datetime whose time portion is always guaranteed to be midnight (and is
therefore irrelevant).  When you C<use Date::Easy>, you get two ways to create dates:

    my $t = today;
    my $d = date($human_readable_string);

and two ways to create datetimes:

    my $n = now;
    my $dt = datetime($human_readable_string);

which pretty much do exactly what you think they do.  Once you have them, you can access individual
attributes of the objects:

    say "day is ", $d->day;
    say "hour is ", $dt->hour;

or you can do simple date math with them.  You may add and subtract integers to/from a date, which
are interpreted as days, and you may add and subtract integers to/from a datetime, which are
interpreted as seconds.  Adding and subtracting units objects to/from dates and datetimes add or
subtract the appropriate quantity of the appropriate unit to/from the date or datetime.

That's really all there is to it, for the basics.

=head2 Limitations

=head3 Time Zones

A date object is always in UTC.  When a string is parsed to get a date, any timezone information in
that string is ignored.  This avoids surprising results such as C<date("20-Jun-2016 9:00pm PDT")>
turning into June 21.

A datetime object is by default in your local timezone (whatever that is).  You can force it to be
in UTC instead in a number of different ways (just search for "UTC" on this page and also on the
page for L<Date::Easy::Datetime>.

=head3 Minima and Maxima

The minimum dates and datetimes that you can represent using Date::Easy objects are the same that
can be represented by epoch seconds (to be more precise, they are the same that can be accepted by
L<Time::Local>'s C<timegm> and C<timelocal>).  For 64-bit machines, I know (from experimentation)
this range to be 1-Jan-1000 00:00:00 to 31-Dec-2899 23:59:59.  For 32-bit machines, I I<believe> it
to be 13-Dec-1901 20:45:52 to 19-Jan-2038 03:14:07, but only prior to Perl 5.12 (Perl 5.12 and above
should handle your epoch seconds as a 64-bit int even when the underlying architecture is 32-bit).

If you are are using a Perl version before 5.12 and your underlying C<time_t> is represented as an
I<unsigned> integer, then all bets are off for you.

=head3 String Formats

The human-readable formats understood by C<date> and C<datetime> are the union of those understood
by L<Date::Parse> and L<Time::ParseDate>.  Date::Parse is tried first, except for a few minor
optimizations where it's easy to know in advance that it can't possibly recognize the format.

=head3 Daylight Savings Time

Date::Easy knows exactly as much about DST as C<localtime>, C<gmtime>, and L<Time::Local> do, which
is to say, it will probably handle most common uses, but may fail for pathological cases.

=head3 Leap Seconds

Date::Easy doesn't deal with leap seconds at all.  In fact, it's likely that the unit tests will
fail during module install if your local timezone includes leap seconds.

=head3 Language

Currently, Date::Easy only speaks English.  Specifically, that means:

=over

=item *

When parsing human-readable strings, it can only understand abbreviations and whole names of days of
the week and months of the year if they are in English.

=item *

When converting to human-readable strings, using C<strftime> (or C<as> with a non-class-string
argument, which just calls C<strftime> underneath), it will I<probably> only render days of the week
and months of the year in English.  However, it I<may> respect the current locale, depending on your
system's underlying POSIX C<strftime> implementation.

=item *

If you convert a unit (L<Date::Easy::Units>) to a string, you get the English name for the unit.

=back

=head1 USAGE

There are a few parameters you can pass to Date::Easy at C<use> time.  These are passed through to
L<Date::Easy::Datetime>.  Thus the following are equivalent:

    use Date::Easy 'local';
    # is the same as:
    use Date::Easy::Date ':all';
    use Date::Easy::Datetime qw< :all local >;
    use Date::Easy::Units ':all';

    use Date::Easy 'UTC';
    # is the same as:
    use Date::Easy::Date ':all';
    use Date::Easy::Datetime qw< :all UTC >;
    use Date::Easy::Units ':all';

    use Date::Easy 'GMT';
    # is the same as:
    use Date::Easy::Date ':all';
    use Date::Easy::Datetime qw< :all GMT >;
    use Date::Easy::Units ':all';

As the Date::Easy::Datetime docs will tell you, "UTC" and "GMT" are exactly equivalent as far as
Date::Easy is concerned.  Passing "local" is redundant, as it is the default, but perhaps you just
want to be explicit.

=head1 DETAILS

For more details on datetimes, see L<Date::Easy::Datetime>.

For more details on dates, see L<Date::Easy::Date>.

For more details on units, see L<Date::Easy::Units>.

=head1 INSPIRATION AND CREDITS

For far more than you ever wanted to know about Date::Easy, including inspirations and design goals,
please refer to my blog series I<L<A Date with
CPAN|http://blogs.perl.org/users/buddy_burden/2015/09/a-date-with-cpan-part-1-state-of-the-union.html>>.

The implementation of both dates and datetimes is almost entirely handled by L<Time::Piece>, by Matt
Sergeant and Jarkko Hietaniemi (based on ideas from Larry Wall).

The interface of datetimes (such as method names and data ranges) more closely conforms to that of
L<DateTime>, by Dave Rolsky.

The interface of constructors (such as `today` and `date`) and that of units objects is shamelessly
stolen from L<Date::Piece>, by Eric Wilhelm.

Date::Easy exists by standing on the shoulders of these giants.  All I did was glue the bits
together.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Date::Easy

=head2 Bugs / Feature Requests

This module is on GitHub.  Feel free to fork and submit patches.  Please note that I develop
via TDD (Test-Driven Development), so a patch that includes a failing test is much more
likely to get accepted (or at least likely to get accepted more quickly).

If you just want to report a problem or suggest a feature, that's okay too.  You can create
an issue on GitHub here: L<http://github.com/barefootcoder/date-easy/issues>.

=head2 Source Code

none
L<https://github.com/barefootcoder/date-easy>

  git clone https://github.com/barefootcoder/date-easy.git

=head1 AUTHOR

Buddy Burden <barefootcoder@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

# Date-Ethiopic
ICalendar for the Ethiopic Calendar System

## About This Release

This is the first release of `Date::Ethiopic` submitted to CPAN.
The package was originally intended to be a part of `Convert::Ethiopic::Lite.
but has inflated to the point where maintenance will be easier
in its own package.  The package will be a work in progress for
quite a while.  It is fully functional for basic date conversions
and should work with any version of Perl.

## About This Package

`Date::Ethiopic` offers services for the Ethiopic calendar system that
are language and culturally neutral.  In addition to `Date::ICal` the
class adds methods for obtaining fasting (Tsome), astrological, and
other info unique to the Ethiopic reckoning of time.

The Ethiopic context is always assumed, a Gregorian context can be
specified when an object is instantiated by adding the "calscale"
argument.  See examples/dates.pl for a demonstration.

The package contains additional classes under the `Date::Ethiopic`
name space that are named under locale conventions.  For example,
`Date::Ethiopic::ET::am`, `Date::Ethiopic::ER::ti`, etc.  These classes
provide localized day and month names as well as formatting.

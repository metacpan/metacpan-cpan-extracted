package Date::Holidays::Abstract;

use strict;
use warnings;
use vars qw($VERSION);
use 5.006;    #perl 5.6.0
use base qw(Class::Virtually::Abstract);

$VERSION = '0.07';

__PACKAGE__->virtual_methods(qw(is_holiday holidays));

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Date-Holidays-Abstract.svg)](http://badge.fury.io/pl/Date-Holidays-Abstract)
[![Build Status](https://travis-ci.org/jonasbn/Date-Holidays-Abstract.svg?branch=master)](https://travis-ci.org/jonasbn/Date-Holidays-Abstract)
[![Coverage Status](https://coveralls.io/repos/jonasbn/Date-Holidays-Abstract/badge.png?branch=master)](https://coveralls.io/r/jonasbn/Date-Holidays-Abstract?branch=master)

=end markdown

=head1 NAME

Date::Holidays::Abstract - abstract class for Date::Holidays::* packages

=head1 SYNOPSIS

    package Date::Holidays::NN;
    use base qw(Date::Holidays::Abstract);

    sub holidays {
    ...
    }

    sub is_holiday {
    ...
    }

=head1 VERSION

This POD describes version 0.07 of Date::Holidays::Abstract

=head1 DESCRIPTION

This module is an abstract class intended for Date::Holidays::*

The goal is to have all the existing and future modules implement the
same methods, so they will have a uniform usage and can be used in
polymorphic context or can be easily adapted into the Date::Holidays
class.

If you want to use Date::Holidays::Abstract and want to comply with my
suggestions to the methods that ought to be implemented, you should
implement:

=over

=item B<is_holiday>

=item B<holidays>

=back

=head2 is_holiday

Should at least take 3 arguments:

=over

=item year, four digits

=item month, between 1-12

=item day, between 1-31

=back

The return value from is holiday is either a 1 or 0 indicating true of
false, indicating whether the specified date is a holiday in the given
country's national calendar.

Additional arguments are at the courtesy of the author of the using
module/class.

=head2 holidays

Should at least take one argument:

=over

=item year, four digits

=back

Returns a reference to a hash, where the keys are date represented as
four digits. The two first representing month (01-12) and the last two
representing day (01-31).

The value for the key in question is the local name for the holiday
indicated by the day. The resultset will of course vary depending on
the given country's national holiday.

Additional arguments are at the courtesy of the author of the using
module/class.

--

L<Date::Holidays> uses the requirements defined by this module and this
module can therefor be used with success in conjunction with this.

This is an alternative to a SUPER class. I have given a lot of thought to
programming a SUPER class, but since creating a super class for a bunch
of modules implementing handling of national holidays, an abstract
class seemed a better choice.

A proposed SUPER class for Date::Holidays::* is however implemented see:
L<Date::Holidays::Super> implement B<is_holiday> and B<holidays> and expect
these to be overloaded.

Overloading would be necessary since nothing intelligent can be said
about holidays without specifying a nationality (a part from holidays
being nice but too few), and the implemented methods would be empty
bodies returning empty result sets.

So I am more for an abstract class and as stated I consider this class
an experiment and I have implemented L<Date::Holidays::Super> as an
alternative.

Suggestions for changes and extensions are more than welcome.

=head1 SUBROUTINES/METHODS

This class does not implement any methods, it is a abstract class.

=head1 DIAGNOSTICS

This class does not implement any exceptions or error, it is a abstract class.

=head1 CONFIGURATION AND ENVIRONMENT

This class does not implement or require any special environment or
configuration apart from what is mentioned in DEPENDENCIES

=head1 DEPENDENCIES

This class is subclassed from L<Class::Virtually::Abstract>, but holds
no direct dependencies apart from that class/module.

=head1 INCOMPATIBILITIES

None known to the author

=head1 BUGS AND LIMITATIONS

None known to the author

=head1 SEE ALSO

=over

=item * L<Date::Holidays>

=item * L<Date::Holidays::Super>

=item * L<Date::Holidays::DE>

=item * L<Date::Holidays::DK>

=item * L<Date::Holidays::FR>

=item * L<Date::Holidays::UK>

=item * L<Date::Holiday::PT>

=item * L<Date::Japanese::Holiday>

=item * L<Class::Virtual>

=item * L<Class::Virtually::Abstract>

=back

=head1 BUGS

Please report issues via CPAN RT:

    L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-Abstract>

or by sending mail to

    L<bug-Date-Holidays-Abstract@rt.cpan.org>

=head1 TEST/COVERAGE

This module is currently at 100% test coverage

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Date-Holidays-Abstract is (C) by Jonas B. Nielsen, (jonasbn) 2004-2014

Date-Holidays-Abstract is released under the Artistic License 2.0

=cut

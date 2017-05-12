# Copyright (c) 2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Exact.pm,v 1.7 2007/06/16 11:39:24 martin Stab $

package Date::Gregorian::Exact;

use strict;
use Carp qw(croak);
use vars qw($VERSION);

$VERSION = 0.99;

sub import {
    croak(__PACKAGE__ . " is no longer available");
}

1;

__END__

=head1 NAME

Date::Gregorian::Exact - abandoned extension of Date::Gregorian

=head1 SYNOPSIS

  # do not use Date::Gregorian::Exact;

=head1 DESCRIPTION

I<Date::Gregorian::Exact> was a subclass extending Date::Gregorian
towards higher precision (sufficient to deal with timestamps).

Due to the simplicity of its data model, however, it never came
close to satisfyingly handle real-life timestamps.  Therefore
it has long been considered deprecated and is now finally abandoned.

Recent versions of the I<DateTime> suite of modules
offer a considerably more substantial approach to the intricacies
of local clocks and timezones.
Please consider using those modules for calculations involving
date and time.

=head1 AUTHOR

Martin Becker <hasch-cpan-dg@cozap.com>, June 2007.

=head1 SEE ALSO

L<Date::Gregorian>, L<DateTime>.

=cut

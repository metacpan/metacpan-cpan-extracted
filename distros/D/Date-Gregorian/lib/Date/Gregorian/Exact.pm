# Copyright (c) 2007-2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

package Date::Gregorian::Exact;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = 0.999;

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

=head1 SEE ALSO

L<Date::Gregorian>, L<DateTime>.

=head1 AUTHOR

Martin Becker C<< <becker-cpan-mp (at) cozap.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 1999-2019 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

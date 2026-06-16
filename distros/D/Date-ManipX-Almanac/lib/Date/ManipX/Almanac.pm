package Date::ManipX::Almanac;

use 5.010;

use strict;
use warnings;

use parent qw{ Date::Manip };

Date::Manip->import();

use Date::ManipX::Almanac::Date;

our @EXPORT = @Date::Manip::EXPORT;

# use Carp;

our $VERSION = '0.004';

1;

__END__

=head1 NAME

Date::ManipX::Almanac - Add almanac date/time functionality (sunrise, etc.) to Date::Manip

=head1 SYNOPSIS

See L<Date::ManipX::Almanac::Date|Date::ManipX::Almanac::Date>.

=head1 DESCRIPTION

The C<Date-ManipX-Almanac> package adds almanac dates/times to
L<Date::Manip|Date::Manip>: things like C<'sunrise'>, C<'full moon'>,
and C<'Venus sets'>.

At the moment only dates are supported (via
L<Date::ManipX::Almanac::Date|Date::ManipX::Almanac::Date>), and this
module is simply a place-holder for the top of the hierarchy.

B<However> this module is a subclass of L<Date::Manip|Date::Manip>, so
that you can probe for C<DM5> or C<DM6> functionality with C<isa()>. Of
course, if C<< Date::ManipX::Almanac->isa( 'Date::Manip::DM6' ) >>
returns a false value it is probably a bug.

=head1 SEE ALSO

L<Date::Manip|Date::Manip>

L<Date::Manip::Date|Date::Manip::Date>

L<Date::ManipX::Almanac::Date|Date::ManipX::Almanac::Date>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://github.com/trwyant/perl-Date-ManipX-Almanac/issues> or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<harryfmudd at comcast dot net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021-2022, 2026 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the files F<LICENSE-Artistic> and F<LICENSE-GPL>.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

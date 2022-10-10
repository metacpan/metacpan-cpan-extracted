package My::Module::Test;

use 5.010;

use strict;
use warnings;

use Carp;

our $VERSION = '0.003';

use Exporter qw{ import };

our @EXPORT_OK = qw{
    CLASS_VENUS
    NO_STAR
    NO_VENUS
    TEST_CONFIG_FILE
    parsed_value
};
our @EXPORT = @EXPORT_OK;

use constant CLASS_VENUS	=> 'Astro::Coord::ECI::VSOP87D::Venus';

BEGIN {
    local $@ = undef;

    use constant NO_STAR	=> eval {
	require Astro::Coord::ECI::Star;
	1;
    } ? '' : 'Astro::Coord::ECI::Star not available';

    use constant NO_VENUS	=> eval {
	require Astro::Coord::ECI::VSOP87D::Venus;
	1;
    } ? '' : 'Astro::Coord::ECI::VSOP87D::Venus not available';

}

use constant TEST_CONFIG_FILE => NO_STAR ?
    't/data/white-house.cfg' :
    't/data/white-house-with-star.cfg';

sub parsed_value {
    my ( $obj, $string ) = @_;
    $obj->parse( $string )
	or return $obj->value( 'gmt' );
    return $obj->err() . " '$string'";
}


1;

__END__

=head1 NAME

My::Module::Test - Provide test support for Date::ManipX::Almanac

=head1 SYNOPSIS

 use Test2::V0;

 use lib qw{ inc };
 use My::Module::Test;

 is parsed_value( $dmad, '2021 vernal equinox' ),
   '2021032009:37:06', 'Vernal equinox 2021';

=head1 DESCRIPTION

This Perl module provides testing support for
L<Date::ManipX::Almanac|Date::ManipX::Almanac>. It is private to the
C<Date-ManipX-Almanac> distribution, and subject to change without
notice. Documentation is for the benefit of the author.

=head1 SUBROUTINES

All subroutines are exported by default, unless otherwise documented.

=head2 parsed_value

 is parsed_value( $dmad, '2021 vernal equinox' ),
   '2021032009:37:06', 'Vernal equinox 2021';

This subroutine takes as its arguments a
L<Date::Manip::Almanac::Date|Date::Manip::Almanac::Date> object and a
string for it to parse. If the parse succeeds, it returns the results of
C<< $dmad->value( 'gmt' ) >>. If it fails, it returns C<< $dmad->err() >>.

=head1 MANIFEST CONSTANTS

All manifest constants are exported unless otherwise documented.

=head2 CLASS_VENUS

This convenience constant is C<'Astro::Coord::ECI::Venus'>.

=head2 NO_STAR

This manifest constant is false if
L<Astro::Coord::ECI::Star|Astro::Coord::ECI::Star> can be loaded. If
not, it is true, and is in fact an appropriate skip message.

=head2 NO_VENUS

This manifest constant is false if
L<Astro::Coord::ECI::Venus|Astro::Coord::ECI::Venus> can be loaded. If
not, it is true, and is in fact an appropriate skip message.

=head2 TEST_CONFIG_FILE

This manifest constant is the name of the configuration file to be
loaded for testing. B<Note> that it depends on the value of
L<HAVE_STAR|/HAVE_STAR>.

=head1 SEE ALSO

L<Date::Manip::Almanac::Date|Date::Manip::Almanac::Date>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Date-ManipX-Almanac>,
L<https://github.com/trwyant/perl-Date-ManipX-Almanac/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

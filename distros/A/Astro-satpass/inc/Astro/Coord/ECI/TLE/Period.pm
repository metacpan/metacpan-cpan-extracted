package Astro::Coord::ECI::TLE::Period;

use 5.006002;

use strict;
use warnings;

use Astro::Coord::ECI::TLE;
use Carp;

our @ISA = qw{ Astro::Coord::ECI::TLE };
our $VERSION = '0.122';

my $pkg = __PACKAGE__;

sub new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new();
    $self->{$pkg}{period} = delete $args{period};
    $self->set( %args );
    return $self;
}

sub period {
    my ( $self ) = @_;
    return $self->{$pkg}{period};
}

1;

__END__

=head1 NAME

Astro::Coord::ECI::TLE::Period - Ad-hoc object with specified period and eccentricity, for testing.

=head1 SYNOPSIS

 use Astro::Coord::ECI::TLE::Period;
 my $tle = Astro::Coord::ECI::TLE::Period->new(
     period       => $period,		# seconds
     eccentricity => $eccentricity,
     name         => $name,
 );

=head1 DESCRIPTION

This Perl module is B<private> to this distribution. It is intended for
use in testing, and is not supported in any way, shape, or form. It is
intended for use in testing the calculation of various orbital
parameters from the period and eccentricity.

=head1 METHODS

This class supports the following methods, which are documented for the
benefit of the author only:

=head2 new

This static method instantiates the object. In its intended use the only
arguments are C<'period'> (in seconds), C<'eccentricity'>, C<'name'>,
and C<'id'>.

=head2 period

This override of the parent's C<period()> method simply returns the
value with which the object was initialized.

=head1 SEE ALSO

L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-satpass>,
L<https://github.com/trwyant/perl-Astro-Coord-ECI/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

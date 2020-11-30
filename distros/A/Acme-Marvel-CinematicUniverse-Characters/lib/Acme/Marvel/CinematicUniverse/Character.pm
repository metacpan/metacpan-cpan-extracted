use 5.008;
use strict;
use warnings;

package Acme::Marvel::CinematicUniverse::Character;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Class::Tiny qw(
	real_name
	hero_name
	intelligence
	strength
	speed
	durability
	energy_projection
	fighting_ability
);

use overload (
	q[bool]  => sub { !!1 },
	q[""]    => sub { shift->real_name },
	q[0+]    => sub { shift->power },
	fallback => !!1,
);

sub power {
	my $self = shift;
	my $sum;
	$sum += $self->$_ for qw(
		intelligence
		strength
		speed
		durability
		energy_projection
		fighting_ability
	);
	return $sum;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::Marvel::CinematicUniverse::Character - a character from the MCU

=head1 DESCRIPTION

A lightweight object representing a character.

=head2 Attributes

=over

=item C<real_name>

The real life name of the character.

=item C<hero_name>

The name they go by as a hero.

=item C<intelligence>, C<strength>, C<speed>, C<durability>, C<energy_projection>, C<fighting_ability>

Values from 1 (lowest) to 7 (highest) from the Marvel power grid.

=back

=head2 Methods

=over

=item C<power>

Returns the sum of the character's six values from the power grid.

=back

=head2 Overloading

=over

=item *

Stringy

The real name of the character.

=item *

Numeric

The power of the character.

=item *

Boolean

Always returns true.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Marvel-CinematicUniverse-Characters>.

=head1 SEE ALSO

L<Acme::Marvel::CinematicUniverse::Characters>,
L<WWW::Marvel>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


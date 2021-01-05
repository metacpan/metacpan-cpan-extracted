package Astro::Montenbruck;
use 5.22.0;
use strict;
use warnings;

our $VERSION = 1.03;

1;
__END__


=pod

=encoding UTF-8

=head1 NAME

Montenbruck - Lightweight Ephemeris

=head1 DESCRIPTION

Library of astronomical calculations, based mainly on
I<"Astronomy On The Personal Computer"> by I<O.Montenbruck> and I<T.Phleger>,
I<Fourth Edition, Springer-Verlag, 2000>.

There are many astronomical libraries available in the public domain. While
giving accurate results, they often suffer from lack of convenient API,
documentation and maintainability. Most of the source code is written in C, C++
or Java, and not dynamic languages. So, it is not easy for a layman to customize
them for her custom application, be it an online lunar calendar, or tool for
amateur sky observations. This library is an attempt to find a middle-ground
between precision on the one hand and compact, well organized code on the other.

=head2 Accuracy

As authors of the book state, they have tried to obtain an accuracy that is
approximately the same as that found in astronomical yearbooks.

"The errors in the fundamental routines for determining the coordinates
of the Sun, the Moon, and the planets amount to about 1″-3″."

-- Introduction to the 4-th edition, p.2.

=head1 MODULES

=over

=item * L<Astro::Montenbruck::MathUtils> — Core mathematical routines.

=item * L<Astro::Montenbruck::Time> — Time-related routines.

=item * L<Astro::Montenbruck::Ephemeris> — Positions of celestial bodies.

=item * L<Astro::Montenbruck::CoCo> — Coordinates conversions.

=item * L<Astro::Montenbruck::NutEqu> — Nutation and obliquity of ecliptic.

=item * L<Astro::Montenbruck::RiseSet> — Rise, set, transit and twilight time.

=item * L<Astro::Montenbruck::Lunation> — Lunar phases.

=item * L<Astro::Montenbruck::SolEqu> — Solstices and equinoxes

=back


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

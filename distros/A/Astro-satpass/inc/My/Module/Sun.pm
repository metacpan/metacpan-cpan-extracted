package My::Module::Sun;

use 5.006002;

use strict;
use warnings;

use base qw{ Astro::Coord::ECI::Sun };

use Carp;

our $VERSION = '0.101';


1;

__END__

=head1 NAME

My::Module::Sun - Fake Sun to test ability to provide one

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Sun;
 # And then, for example
 my @rslt = Astro::Coord::ECI::TLE->parse(
     { sun => 'My::Module::Sun },
     $tle_text,
 );

=head1 DESCRIPTION

This subclass of L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun> is
used to test the ability to provide a C<sun> attribute other than the
default.

This module is private to this distribution, and can be modified or
retracted without notice.

=head1 METHODS

This class adds no methods.

=head1 ATTRIBUTES

This class adds no attributes.


=head1 SEE ALSO

L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

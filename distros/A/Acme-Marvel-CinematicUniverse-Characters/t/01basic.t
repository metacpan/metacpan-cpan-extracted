=pod

=encoding utf-8

=head1 PURPOSE

Test that Acme::Marvel::CinematicUniverse::Characters compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

my $module = 'Acme::Marvel::CinematicUniverse::Characters';

use_ok($module);

is scalar($module->characters), 6, 'Six characters';

my ( $ironman ) = $module->find('Tony');

ok( $ironman, 'Found Tony Stark' );

is( "$ironman", 'Tony Stark', 'Tony Stark stringifies correctly' );

is( $ironman + 0, 33, 'Tony Start numifies correctly' );

my $cap = $module->find(qr/Steve/);

ok( $ironman > $cap, 'Iron Man > Captain America' );

done_testing;


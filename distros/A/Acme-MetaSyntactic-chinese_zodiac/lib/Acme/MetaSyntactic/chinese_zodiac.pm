package Acme::MetaSyntactic::chinese_zodiac;

our $DATE = '2017-02-04'; # DATE
our $VERSION = '0.002'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: The Chinese zodiac theme

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::chinese_zodiac - The Chinese zodiac theme

=head1 VERSION

This document describes version 0.002 of Acme::MetaSyntactic::chinese_zodiac (from Perl distribution Acme-MetaSyntactic-chinese_zodiac), released on 2017-02-04.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=chinese_zodiac -le 'print metaname'
 rooster

 % meta chinese_zodiac 2
 rooster
 horse

 % meta chinese_zodiac/zodiac_element 2
 fire_dragon
 wood_pig

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-chinese_zodiac>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-chinese_zodiac>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-chinese_zodiac>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# default
zodiac
# names zodiac
snake horse goat monkey rooster dog pig rat ox tiger rabbit dragon
# names element
wood fire earth metal water
# names zodiac_element
wood_snake
wood_horse
wood_goat
wood_monkey
wood_rooster
wood_dog
wood_pig
wood_rat
wood_ox
wood_tiger
wood_rabbit
wood_dragon
fire_snake
fire_horse
fire_goat
fire_monkey
fire_rooster
fire_dog
fire_pig
fire_rat
fire_ox
fire_tiger
fire_rabbit
fire_dragon
earth_snake
earth_horse
earth_goat
earth_monkey
earth_rooster
earth_dog
earth_pig
earth_rat
earth_ox
earth_tiger
earth_rabbit
earth_dragon
metal_snake
metal_horse
metal_goat
metal_monkey
metal_rooster
metal_dog
metal_pig
metal_rat
metal_ox
metal_tiger
metal_rabbit
metal_dragon
water_snake
water_horse
water_goat
water_monkey
water_rooster
water_dog
water_pig
water_rat
water_ox
water_tiger
water_rabbit
water_dragon

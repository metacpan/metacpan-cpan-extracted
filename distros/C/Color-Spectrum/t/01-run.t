#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 17;

use Color::Spectrum;

my $color = new_ok 'Color::Spectrum';

my @pcolor = Color::Spectrum::generate(4,"#FFFFFF","#000000");
is @pcolor, 4, 'elements generated (exported)';

my @ocolor = $color->generate(4,"#FFFFFF","#000000");
is @ocolor, 4, 'elements generated (instantiated)';

is eq_array( \@pcolor, \@ocolor ), 1, 'export vs instantiation';

my @color = $color->generate(0,"#FFFFFF","#000000");
is @color, 1, 'fix for bug 43939';

@color = $color->generate(2,"#FFFFFF","#000000");
is $color[0], '#FFFFFF', 'fix for bug 44015';
is $color[1], '#000000', 'fix for bug 44015';

@color = $color->generate(10,"#FFFFFF","#000000");
is $color[0], '#FFFFFF', 'first element is first color';
is $color[9], '#000000', 'last element is last color';

@color = $color->generate(10,"FFFFFF","000000");
is $color[0], '#FFFFFF', 'first element has hash';
is $color[9], '#000000', 'last element has hash';

@color = $color->generate(10,"FFF","000");
is $color[0], '#FFFFFF', 'first element expanded to 6 chars';
is $color[9], '#000000', 'last element expanded to 6 chars';

@color = $color->generate(10,"red","black");
is $color[0], '#FF0000', 'first element translated';
is $color[9], '#000000', 'last element translated';

eval { @color = $color->generate(10,"foo","blue") };
like $@, qr/^Invalid color foo/, 'caught invalid color exception for 2nd arg';

eval { @color = $color->generate(10,"blue","baz") };
like $@, qr/^Invalid color baz/, 'caught invalid color exception for 3nd arg';



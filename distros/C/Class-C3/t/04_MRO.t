use strict;
use warnings;

use Test::More tests => 1;

=pod

example taken from: L<http://gauss.gwydiondylan.org/books/drm/drm_50.html>

         Object
           ^
           |
        LifeForm
         ^    ^
        /      \
   Sentient    BiPedal
      ^          ^
      |          |
 Intelligent  Humanoid
       ^        ^
        \      /
         Vulcan

 define class <sentient> (<life-form>) end class;
 define class <bipedal> (<life-form>) end class;
 define class <intelligent> (<sentient>) end class;
 define class <humanoid> (<bipedal>) end class;
 define class <vulcan> (<intelligent>, <humanoid>) end class;

=cut

{
    package Object;
    use Class::C3;

    package LifeForm;
    use Class::C3;
    BEGIN { our @ISA = ('Object'); }

    package Sentient;
    use Class::C3;
    BEGIN { our @ISA = ('LifeForm'); }

    package BiPedal;
    use Class::C3;
    BEGIN { our @ISA = ('LifeForm'); }

    package Intelligent;
    use Class::C3;
    BEGIN { our @ISA = ('Sentient'); }

    package Humanoid;
    use Class::C3;
    BEGIN { our @ISA = ('BiPedal'); }

    package Vulcan;
    use Class::C3;
    BEGIN { our @ISA = ('Intelligent', 'Humanoid'); }
}

Class::C3::initialize();

is_deeply(
    [ Class::C3::calculateMRO('Vulcan') ],
    [ qw(Vulcan Intelligent Sentient Humanoid BiPedal LifeForm Object) ],
    '... got the right MRO for the Vulcan Dylan Example');

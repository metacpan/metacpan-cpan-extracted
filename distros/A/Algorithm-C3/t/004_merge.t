use strict;
use warnings;

use Test::More tests => 1;

use Algorithm::C3;

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

    sub my_ISA {
        no strict 'refs';
        @{$_[0] . '::ISA'};
    }

    package LifeForm;
    our @ISA = qw(Object);

    package Sentient;
    our @ISA = qw(LifeForm);

    package BiPedal;
    our @ISA = qw(LifeForm);

    package Intelligent;
    our @ISA = qw(Sentient);

    package Humanoid;
    our @ISA = qw(BiPedal);

    package Vulcan;
    our @ISA = qw(Intelligent Humanoid);
}

is_deeply(
    [ Algorithm::C3::merge('Vulcan', 'my_ISA') ],
    [ qw(Vulcan Intelligent Sentient Humanoid BiPedal LifeForm Object) ],
    '... got the right C3 merge order for the Vulcan Dylan Example');

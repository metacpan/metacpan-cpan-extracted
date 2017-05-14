use strict;
use warnings;
use Test::More;

use Acme::Auggy;

my $auggy = Acme::Auggy::say_auggy;
is($auggy, 'Auggy', "Check that say_auggy says Auggy");

my $auggy_is = Acme::Auggy::say_auggy_is('Awesome!');
is($auggy_is, 'Auggy is Awesome!', 'Check that say_auggy_is says Auggy is Awesome!');

done_testing;

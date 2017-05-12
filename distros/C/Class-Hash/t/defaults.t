# vim: set ft=perl :

use Test::More tests => 2;
use Class::Hash fetch => 1, store => 1;

is_deeply(Class::Hash->defaults, { fetch => 1, store => 1 }, 'default options');

my $hash = Class::Hash->new;

is_deeply(Class::Hash->options($hash), { fetch => 1, store => 1 }, 'default options');

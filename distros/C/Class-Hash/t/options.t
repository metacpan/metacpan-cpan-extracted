# vim: set ft=perl :

use Test::More tests => 1;
use Class::Hash;

my $hash = Class::Hash->new({ fetch => 1, store => 1 });

is_deeply(Class::Hash->options($hash), { fetch => 1, store => 1 }, 'default options');

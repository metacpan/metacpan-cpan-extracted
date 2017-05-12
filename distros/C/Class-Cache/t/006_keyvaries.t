# -*- perl -*-

use Test::More qw(no_plan);

use Data::Dumper;
use Class::Cache;

my $c   = Class::Cache->new;
my $pkg = 'Class::Cache::Test::Adder';
$c->set(la => { lazy => 1, pkg => $pkg,, args => [10,11,12] });
is($c->get('la')->add, 33, 'cache key differs from package name');

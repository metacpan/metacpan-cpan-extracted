# -*- perl -*-

# t/005_all_defaults.t - check construction with all defaults

use Test::More qw(no_plan);

use Data::Dumper;
use Class::Cache;

my $c   = Class::Cache->new;
my $pkg = 'Class::Cache::Test::MeaningOfUniverse';
$c->set($pkg => 1);
is($c->get($pkg)->divulge, 42, 'conc with all defaults');

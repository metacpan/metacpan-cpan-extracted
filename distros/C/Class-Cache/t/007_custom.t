# -*- perl -*-

use Test::More qw(no_plan);

use Data::Dumper;
use Class::Cache;

my $c   = Class::Cache->new;
my $pkg = 'Class::Cache::Test::Adder';

eval "require $pkg";
die $@ if $@;

$c->set(
  la => {
    lazy => 1,
    new => sub {
      my $a = $pkg->new(22,44,11);
    }
   }
 );

is($c->get('la')->add, 77);


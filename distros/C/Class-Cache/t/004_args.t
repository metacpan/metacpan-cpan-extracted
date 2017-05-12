# -*- perl -*-

# t/005_args.t - check construction with all defaults

use Test::More qw(no_plan);

use Data::Dumper;
use Class::Cache;

my $c = Class::Cache->new(lazy => 1);


sub compare_arrays {
  my ($first, $second) = @_;
  no warnings;  # silence spurious -w undef complaints
  return 0 unless @$first == @$second;
  for (my $i = 0; $i < @$first; $i++) {
    return 0 if $first->[$i] ne $second->[$i];
  }
  return 1;
}

# all can be constructed by simply calling new;
my $pkg = Class::Cache::Test::Adder;


$c->set( $pkg => { args => [1,2,3] } ) ;

my $adder = $c->get($pkg);
my $sum   = $adder->add;

is($sum, 6, 'object retrieved and used');


# -*- perl -*-

# t/003_lazy.t - check lazy slot creation

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
my @simple = qw(CGI FileHandle Class::Cache::Test::Lazy SelectSaver);


for (@simple) {
  $c->set($_ => 1);
}

ok(
  compare_arrays(
    [sort @simple], 
    [sort $c->classes]
   ), 
  'all classes constructed'
 );


my $warn = $c->get('Class::Cache::Test::Lazy');
warn $warn;

ok(
  compare_arrays(
    [sort qw(FileHandle CGI SelectSaver)], 
    [sort $c->classes]
   ), 
  'lazy class not in cache'
 );

$c->refill;

#warn join ':', $c->classes;

ok(
  compare_arrays(
    [sort @simple], 
    [sort $c->classes]
   ), 
  'all classes constructed'
 );


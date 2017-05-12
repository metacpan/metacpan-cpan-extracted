# -*- perl -*-

# t/001_usage.t - check module usage

use Test::More qw(no_plan);

use Data::Dumper;
use Class::Cache;

my $c = Class::Cache->new;


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
my @simple = qw(CGI FileHandle SelectSaver);


for (@simple) {
  $c->set($_ => 1);
}

ok(compare_arrays([sort @simple], 
		  [sort $c->classes]), 
   'all classes constructed');


$c->get('CGI');

warn join '-+-', $c->classes;

ok(compare_arrays(
  [sort qw(FileHandle SelectSaver)], 
  [sort $c->classes]), 
   'CGI not in cache'
 );

$c->refill;



ok(compare_arrays([ sort @simple], [sort $c->classes]), 'all classes constructed');


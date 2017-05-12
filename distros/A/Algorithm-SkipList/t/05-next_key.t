#-*- mode: perl;-*-

package main;

use constant SIZE => 5;

use Test::More tests => 6+(4*SIZE);
use Algorithm::SkipList 0.70;
ok(1);

my $List = new Algorithm::SkipList;

{
  no warnings;
  ok(!defined $List->first_key); # make sure this returns nothing
}

my @data = sort (0..(SIZE-1)); # test '0' as key for last_key

my %hash = map { $_ => sprintf('%04d', $_); } @data;

ok(SIZE == @data);

foreach (@data) {
  $List->insert($_, $hash{$_});
}
ok($List->size == @data);

# check that next_key works without first_key

foreach (@data) {
  ok($_ eq $List->next_key);
}

# check that first_key/next_key still work
{
  my $i = 0;

  ok($data[$i++] eq $List->first_key);

  while (my $key = $List->next_key) {
    ok($data[$i++] eq $key);
  }
}

# test reset method

{
  ok($data[0] eq $List->first_key);
  $List->reset;
  ok($data[0] eq $List->next_key);
}

$List->reset;

{
  my $i = 0;

  while (my ($key, $value) = $List->next) {
    ok($data[$i++] eq $key);
    ok($hash{$key} eq $value);
  }
}

__END__

$List->reset;

my @prev = reverse @data;

{
  my $i = 0;

  while (my ($key, $value) = $List->prev) {
    print STDERR "\t$key\t$value\n";
#    ok($prev[$i++] eq $key);
#    ok($hash{$key} eq $value);
  }
}

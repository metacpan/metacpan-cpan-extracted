#testing if the add method works.
use Date::Roman;
use strict;
my @data;

BEGIN {
  open DATA,"<test-data/add.txt" || die "can't open test-data/add.txt: $!";
  while (<DATA>) {
    next if /^#/;
    chomp;
    push @data,$_;
  }
  close DATA;
}

use Test::More tests => 4 + 6 * (@data - 1);

my ($i,$base);

$base = Date::Roman->new(roman => $data[0]);
ok(defined $base);
ok($base->isa('Date::Roman'));

foreach $i (1..$#data) {
  my $tmp = $base->add($i);
  
  ok(defined $tmp);
  ok($tmp->isa('Date::Roman'));

  is($tmp->roman(),$data[$i]);

}



$base = Date::Roman->new(roman => $data[$#data]);
ok(defined $base);
ok($base->isa('Date::Roman'));

foreach $i (1..$#data) {
  my $tmp = $base->add(-$i);
  
  ok(defined $tmp);
  ok($tmp->isa('Date::Roman'));

  is($tmp->roman(),$data[$#data - $i]);

}


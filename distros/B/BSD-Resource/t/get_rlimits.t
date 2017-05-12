#
# get_rlimits.t
#
# https://rt.cpan.org/Ticket/Display.html?id=108955
#

use BSD::Resource;

local $^W = 1;

my $r = get_rlimits();
my @r = sort keys %$r; 

printf("1..%d\n", scalar @r);

for my $i (1..@r) {
  my $k = $r[$i - 1]; 
  my $res = $r->{$k};
  my $val = eval "&BSD::Resource::${res}()";
  print defined $val ? "not ok $i # $k\n" : "ok $i # $k $res\n";
}

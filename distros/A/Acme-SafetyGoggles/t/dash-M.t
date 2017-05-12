use Test::More tests => 17;
use strict;
use warnings;

# exercise Acme::SafetyGoggles when it is invoked
# with  -MAcme::SafetyGoggles
my $VAR1;

##################################  base case
chomp(my @v = qx($^X t/my_code.pl));
ok(@v==1 && $v[0] eq '7 times 6 equals 42', 'base case');

##################################  safe filter
chomp(@v = qx($^X -Mt::SafeSourceFilter t/my_code.pl));
ok(@v==1 && $v[0] eq '7 times 6 equals 42', 'safe filter');

chomp(@v = qx($^X -Iblib/lib -MAcme::SafetyGoggles -Mt::SafeSourceFilter t/my_code.pl));
ok(@v==2 && $v[0] eq '7 times 6 equals 42', 'safe filter with goggles')
	or diag @v[1..$#v];
my $w = eval join"\n",@v[1..$#v];
ok(@$w==3 && $w->[0]==42 && $w->[1] eq 'safe' && $w->[2] eq '',
   'certified safe by Acme::SafetyGoggles');

chomp(@v = qx($^X -Iblib/lib -Mt::SafeSourceFilter -MAcme::SafetyGoggles t/my_code.pl));
ok(@v==2 && $v[0] eq '7 times 6 equals 42', 'safe filter with goggles');
$w=eval join"\n",@v[1..$#v];
ok(@$w==3 && $w->[0]==42 && $w->[1] eq 'safe' && $w->[2] eq '',
   'certified safe by Acme::SafetyGoggles');


chomp(@v = qx($^X t/my_safe_code.pl));
ok(@v==1 && $v[0] eq '7 times 6 equals 42', 'safe filter');

chomp(@v = qx($^X -Iblib/lib -MAcme::SafetyGoggles t/my_safe_code.pl));
ok(@v==2 && $v[0] eq '7 times 6 equals 42', 'safe filter with goggles');
$w = eval join"\n",@v[1..$#v];
ok(@$w==3 && $w->[0]==42 && $w->[1] eq 'safe' && $w->[2] eq '',
   'certified safe by Acme::SafetyGoggles');



###################################  unsafe filter
chomp(@v = qx($^X -Mt::UnsafeSourceFilter t/my_code.pl));
ok(@v==1 && $v[0] eq '7 times 6 equals 19', 'unsafe filter');

chomp(@v = qx($^X -Iblib/lib -MAcme::SafetyGoggles -Mt::UnsafeSourceFilter t/my_code.pl));
ok(@v>=2 && $v[0] eq '7 times 6 equals 19', 'unsafe filter with goggles')
	or diag join"\n",@v[1..$#v];
$w=eval join"\n",@v[1..$#v];
ok(@$w==3 && $w->[0]==19 && $w->[1] eq 'unsafe' && $w->[2] ne '',
   'source mod detected by Acme::SafetyGoggles');

chomp(@v = qx($^X -Iblib/lib -Mt::UnsafeSourceFilter -MAcme::SafetyGoggles t/my_code.pl));
ok(@v>=2 && $v[0] eq '7 times 6 equals 19', 'unsafe filter with goggles');
$w=eval join"\n",@v[1..$#v];
ok(@$w==3 && $w->[0]==19 && $w->[1] eq 'unsafe' && $w->[2] ne '',
   'source mod detected by Acme::SafetyGoggles');


chomp(@v = qx($^X t/my_unsafe_code.pl));
ok(@v==1 && $v[0] eq '7 times 6 equals 19', 'unsafe filter');

chomp(@v = qx($^X -Iblib/lib -MAcme::SafetyGoggles t/my_unsafe_code.pl));
ok(@v>=2 && $v[0] eq '7 times 6 equals 19', 'unsafe filter with goggles')
	or diag join"\n",@v[1..$#v];
$w=eval join"\n",@v[1..$#v];
ok(@$w==3 && $w->[0]==19 && $w->[1] eq 'unsafe' && $w->[2] ne '',
   'source mod detected by Acme::SafetyGoggles');



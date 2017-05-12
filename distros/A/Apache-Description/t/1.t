
use Test::More tests => 2;
BEGIN { use_ok('Apache::Description') };

#########################

my $d = Apache::Description->new;
isa_ok($d, "Apache::Description"); 


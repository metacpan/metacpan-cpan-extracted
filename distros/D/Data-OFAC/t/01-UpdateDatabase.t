use Test;
BEGIN { plan tests => 2 };
use Data::OFAC;

ok(1);

ok(my $ofac = Data::OFAC->new());

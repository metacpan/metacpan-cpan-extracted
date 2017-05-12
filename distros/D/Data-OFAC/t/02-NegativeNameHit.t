use Test;
BEGIN { plan tests => 4 };
use Data::OFAC;

ok(1);

ok(my $ofac = Data::OFAC->new());

ok($result = $ofac->checkName('Hardison, Tyler'));
ok(defined $result ? 1 : 0 );

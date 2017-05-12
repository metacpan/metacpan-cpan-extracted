use strict;

use Math::BigInt;
use Test;

BEGIN { plan tests => 14; }

use DNS::Bananafonana;
ok(1);

# Stealing values from RFC 1924.
my $n = new Math::BigInt("21932261930451111902915077091070067066");
my $m = DNS::Bananafonana::to_bananafonana($n);
$m =~ s/[-_\,]//g;
ok($m, "buvoxanevefitoketegubulipowabasosivakupe");

# Supply some invalid stuff.
my $x = qq("buvoxanevefitoketegubulipowabasosivakup");
eval {
    my $y = DNS::Bananafonana::from_bananafonana($x);
};
ok($@);
ok($@, qr/invalid bananafonana string/);

my $x = qq("buvoxanevefi34ketegubulipowabasosivakupe");
eval {
    my $y = DNS::Bananafonana::from_bananafonana($x);
};
ok($@);
ok($@, qr/invalid bananafonana string/);

# Add 1 and see if we get what we expect.
my $p = "buvoxanevefitoketegubulipowabasosivakupi";
my $q = DNS::Bananafonana::from_bananafonana($p);
my $r = new Math::BigInt("21932261930451111902915077091070067067");
ok($q == $r);

# Same as before, but with separation characters
my $p = "buvoxa.nevefito-ketegubu_lipowa-basosi_vakupi";
my $q = DNS::Bananafonana::from_bananafonana($p);
my $r = new Math::BigInt("21932261930451111902915077091070067067");
ok($q == $r);

# Test a complete IPv4 hostname
my $p = "prefix-boketegubu.example.com";
my $q = DNS::Bananafonana::bananafonana($p, "example.com", "prefix-");
my $r = "10.126.204.174";
ok($q eq $r);

# Test a complete IPv6 hostname
my $p = "prefix-tujufizito-hizufinine-liguzobudu-wopasobego.example.com";
my $q = DNS::Bananafonana::bananafonana($p, "example.com", "prefix-");
my $r = "dcba:dcba:dcba:dcba:dcba:dcba:dcba:dcba";
ok($q eq $r);

# Test an IPv4 PTR record
my $p = "10.11.12.13.in-addr.arpa";
my $q = DNS::Bananafonana::bananafonana($p, "example.com", "prefix-");
my $r = "prefix-bugelepine.example.com";
ok($q eq $r);

# Test an IPv6 PTR record
my $p = "a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.ip6.arpa";
my $q = DNS::Bananafonana::bananafonana($p, "example.com", "prefix-");
my $r = "prefix-tujufizito-hizufinine-liguzobudu-wopasobego.example.com";
ok($q eq $r);

# Test an invalid IPv6 PTR record
my $p = "g.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.a.b.c.d.ip6.arpa";
eval {
my $q = DNS::Bananafonana::bananafonana($p, "example.com", "prefix-");
};
ok($@);
ok($@, qr/cannot encode/);

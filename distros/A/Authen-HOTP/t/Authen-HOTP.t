use Test::More tests => 12;
BEGIN { use_ok('Authen::HOTP', qw(:all)) };

# test vectors from Appendix D of RFC 4226
my $secret = "3132333435363738393031323334353637383930";
my @expected = qw(
    755224
    287082
    359152
    969429
    338314
    254676
    287922
    162583
    399871
    520489
);

for (my $c = 0; $c < @expected; $c++)
{
    ok(hotp($secret, $c) eq $expected[$c]);
}

ok(hotp("12345678901234567890", 30, 6) eq "026920");

use strict;
use warnings;
use lib "blib/lib";
#use Locale::Country;
#my $cc = country2code('Germany');
use Test::More tests => 4;
my $cc = "DE";
BEGIN {
    use_ok('Business::IBAN');
}

my $iban = Business::IBAN->new();
my $ib = $iban->getIBAN(
    {
        ISO => $cc,
        BIC => "36020041",
        AC  => "12345678",
    }
);
ok($ib, "generate IBAN");

my $valid = $iban->valid($ib);
ok($valid, "valid $ib");
$ib = "IBAN DE54360200410012345678";
$valid = $iban->valid($ib);
ok(!$valid, "not valid $ib");


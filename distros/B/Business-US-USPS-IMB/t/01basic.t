use Test::More tests => 5;
BEGIN { use_ok('Business::US::USPS::IMB') };

## Test usps4cb wrapper

my $track_ptr = pack("Z21", "00702901088093000001");
my $route_ptr = pack("Z12","00960040303");
my $bar_ptr = pack("Z66","");

my $results = Business::US::USPS::IMB::usps4cb($track_ptr,$route_ptr,$bar_ptr);

ok(unpack("Z66", $bar_ptr) eq "AFFFTFDTAFTFFATFDDFDTDTAAFFAATDTFFDAADATAAFFTDADATTTFDTTDAAFDTDAT","usps4cb extension");

ok($results == 0, "usps4cb extension");

## Test encode_IMB

my ($bar_string, $result_code) = Business::US::USPS::IMB::encode_IMB("00702901088093000001", "00960040303");

ok($bar_string eq "AFFFTFDTAFTFFATFDDFDTDTAAFFAATDTFFDAADATAAFFTDADATTTFDTTDAAFDTDAT","encode_IMB");
ok($result_code == 0, "encode_IMB");

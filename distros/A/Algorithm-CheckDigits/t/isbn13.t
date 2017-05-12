use Test;
BEGIN {
	plan (
		tests => 4,
#		todo => [3],
	); 
};
use Algorithm::CheckDigits;

my $isbn13 = CheckDigits('isbn13');
my $ean    = CheckDigits('ean');

my $isbn_number             = "9783492233163";
my $ean_but_not_isbn_number = "7622200004607";

ok($isbn13->is_valid($isbn_number),1, "valid ISBN");
ok($ean->is_valid(   $isbn_number),1, "valid EAN");

ok($isbn13->is_valid($ean_but_not_isbn_number),'', "valid EAN but not ISBN");
ok($ean->is_valid(   $ean_but_not_isbn_number),1, "valid EAN");

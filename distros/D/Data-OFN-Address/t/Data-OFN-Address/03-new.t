use strict;
use warnings;

use Data::OFN::Address;
use Data::Text::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 38;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::OFN::Address->new;
isa_ok($obj, 'Data::OFN::Address');

# Test.
$obj = Data::OFN::Address->new(
	'address_place' => 'https://linked.cuzk.cz/resource/ruian/adresni-misto/83163832',
	'address_place_code' => 83163832,
	'cadastral_area' => 'https://linked.cuzk.cz/resource/ruian/katastralni-uzemi/635448',
	'cadastral_area_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Fulnek',
		),
	],
	'conscription_number' => 123,
	'conscription_number_flag' => 'a',
	'district' => 'https://linked.cuzk.cz/resource/ruian/okres/3804',
	'district_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Nový Jičín'),
		),
	],
	'element_ruian' => 'https://linked.cuzk.cz/resource/ruian/parcela/91188411010',
	'house_number' => 386,
	'house_number_type' => decode_utf8('č.p.'),
	'id' => 7,
	'municipality' => 'https://linked.cuzk.cz/resource/ruian/obec/599352',
	'municipality_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Fulnek',
		),
	],
	'municipality_part' => 'https://linked.cuzk.cz/resource/ruian/cast-obce/413551',
	'municipality_part_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => 'Fulnek',
		),
	],
	'psc' => 74245,
	'street' => 'https://linked.cuzk.cz/resource/ruian/ulice/309184',
	'street_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Bílovecká'),
		),
	],
	'text' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Bílovecká 386, 74245 Fulnek'),
		),
	],
	'vusc' => 'https://linked.cuzk.cz/resource/ruian/vusc/132',
	'vusc_name' => [
		Data::Text::Simple->new(
			'lang' => 'cs',
			'text' => decode_utf8('Moravskoslezský kraj'),
		),
	],
);
isa_ok($obj, 'Data::OFN::Address');

# Test.
eval {
	Data::OFN::Address->new(
		'address_place' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'address_place' does not match the specified regular expression.\n",
	"Parameter 'address_place' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'address_place' => 'https://linked.cuzk.cz/resource/ruian/adresni-misto/foo',
	);
};
is($EVAL_ERROR, "Parameter 'address_place' does not match the specified regular expression.\n",
	"Parameter 'address_place' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'address_place_code' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'address_place_code' must be a positive natural number.\n",
	"Parameter 'address_place_code' must be a positive natural number (bad).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'cadastral_area' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'cadastral_area' does not match the specified regular expression.\n",
	"Parameter 'cadastral_area' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'cadastral_area' => 'https://linked.cuzk.cz/resource/ruian/katastralni-uzemi/foo',
	);
};
is($EVAL_ERROR, "Parameter 'cadastral_area' does not match the specified regular expression.\n",
	"Parameter 'cadastral_area' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'cadastral_area_name' => ['bad'],
	);
};
is($EVAL_ERROR, "Cadastral area name isn't 'Data::Text::Simple' object.\n",
	"Cadastral area name isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'cadastral_area_name' => [$mock],
	);
};
is($EVAL_ERROR, "Cadastral area name isn't 'Data::Text::Simple' object.\n",
	"Cadastral area name isn't 'Data::Text::Simple' object (object).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'conscription_number' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'conscription_number' must be a positive natural number.\n",
	"Parameter 'conscription_number' must be a positive natural number (bad).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'conscription_number_flag' => 'a',
	);
};
is($EVAL_ERROR, "Parameter 'conscription_number_flag' is possible with 'conscription_number' parameter only.\n",
	"Parameter 'conscription_number_flag' is possible with 'conscription_number' parameter only.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'element_ruian' => '91188411010',
	);
};
is($EVAL_ERROR, "Parameter 'element_ruian' does not match the specified regular expression.\n",
	"Parameter 'element_ruian' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'house_number' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'house_number' must be a positive natural number.\n",
	"Parameter 'house_number' must be a positive natural number (bad).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'house_number_type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'house_number_type' must be one of defined strings.\n",
	"Parameter 'house_number_type' must be one of defined strings.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'momc' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'momc' does not match the specified regular expression.\n",
	"Parameter 'momc' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'momc_name' => ['bad'],
	);
};
is($EVAL_ERROR, "MOMC name isn't 'Data::Text::Simple' object.\n",
	"MOMC name isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'momc_name' => [$mock],
	);
};
is($EVAL_ERROR, "MOMC name isn't 'Data::Text::Simple' object.\n",
	"MOMC name isn't 'Data::Text::Simple' object (object).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'mop' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'mop' does not match the specified regular expression.\n",
	"Parameter 'mop' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'mop_name' => ['bad'],
	);
};
is($EVAL_ERROR, "MOP name isn't 'Data::Text::Simple' object.\n",
	"MOP name isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'mop_name' => [$mock],
	);
};
is($EVAL_ERROR, "MOP name isn't 'Data::Text::Simple' object.\n",
	"MOP name isn't 'Data::Text::Simple' object (object).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'municipality' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'municipality' does not match the specified regular expression.\n",
	"Parameter 'municipality' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'municipality_name' => ['bad'],
	);
};
is($EVAL_ERROR, "Municipality name isn't 'Data::Text::Simple' object.\n",
	"Municipality name isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'municipality_name' => [$mock],
	);
};
is($EVAL_ERROR, "Municipality name isn't 'Data::Text::Simple' object.\n",
	"Municipality name isn't 'Data::Text::Simple' object (object).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'municipality_part' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'municipality_part' does not match the specified regular expression.\n",
	"Parameter 'municipality_part' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'municipality_part_name' => ['bad'],
	);
};
is($EVAL_ERROR, "Municipality part name isn't 'Data::Text::Simple' object.\n",
	"Municipality part name isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'municipality_part_name' => [$mock],
	);
};
is($EVAL_ERROR, "Municipality part name isn't 'Data::Text::Simple' object.\n",
	"Municipality part name isn't 'Data::Text::Simple' object (object).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'psc' => 'baddd',
	);
};
is($EVAL_ERROR, "Parameter 'psc' does not match the specified regular expression.\n",
	"Parameter 'psc' does not match the specified regular expression. (baddd).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'psc' => '1234',
	);
};
is($EVAL_ERROR, "Parameter 'psc' has length different than '5'.\n",
	"Parameter 'psc' has length different than '5'.(1234).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'psc' => '123456',
	);
};
is($EVAL_ERROR, "Parameter 'psc' has length different than '5'.\n",
	"Parameter 'psc' has length different than '5'. (123456).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'street' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'street' does not match the specified regular expression.\n",
	"Parameter 'street' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'street_name' => ['bad'],
	);
};
is($EVAL_ERROR, "Street name isn't 'Data::Text::Simple' object.\n",
	"Street name isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'street_name' => [$mock],
	);
};
is($EVAL_ERROR, "Street name isn't 'Data::Text::Simple' object.\n",
	"Street name isn't 'Data::Text::Simple' object (object).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'text' => ['bad'],
	);
};
is($EVAL_ERROR, "Text isn't 'Data::Text::Simple' object.\n",
	"Text isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'text' => [$mock],
	);
};
is($EVAL_ERROR, "Text isn't 'Data::Text::Simple' object.\n",
	"Text isn't 'Data::Text::Simple' object (object).");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'vusc' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'vusc' does not match the specified regular expression.\n",
	"Parameter 'vusc' does not match the specified regular expression.");
clean();

# Test.
eval {
	Data::OFN::Address->new(
		'vusc_name' => ['bad'],
	);
};
is($EVAL_ERROR, "VUSC name isn't 'Data::Text::Simple' object.\n",
	"VUSC name isn't 'Data::Text::Simple' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::OFN::Address->new(
		'vusc_name' => [$mock],
	);
};
is($EVAL_ERROR, "VUSC name isn't 'Data::Text::Simple' object.\n",
	"VUSC name isn't 'Data::Text::Simple' object (object).");
clean();

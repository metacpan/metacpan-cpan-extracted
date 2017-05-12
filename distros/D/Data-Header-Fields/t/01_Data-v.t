#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;
use Test::Exception;
use Test::Deep;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'Data::v' ) or exit;
}

exit main();

sub main {
	my $vcard      = Data::v::Card->new();

	my $vcard_line3 = Data::v::Card::Line->new(
		'line'   => "VERSION:2.1\n",
		'parent' => $vcard,
	);
	is($vcard_line3->get_key_param_value('encoding'), undef, 'get_key_param_value()');
	cmp_ok($vcard_line3->value, 'eq', "2.1", 'value()');
	is($vcard_line3->as_string, "VERSION:2.1\n", 'line->as_string()');

	my $vcard_line = Data::v::Card::Line->new(
		'line'   => "PHOTO;VALUE=URL;TYPE=GIF:http://www.example.com/dir_photos/my_photo.gif\n",
		'parent' => $vcard,
	);
	$vcard_line->line_changed;
	is($vcard_line->version, '2.1', 'default vcard version is 2.1');
	is($vcard_line->key, 'PHOTO', 'line key');
	cmp_ok($vcard_line->value, 'eq', 'http://www.example.com/dir_photos/my_photo.gif', 'line value');
	cmp_deeply([
		map { {'name'=>$_->name, 'value'=>$_->value} } @{$vcard_line->params}],
		[{'name' => 'VALUE', 'value' => 'URL'}, {'name' => 'TYPE', 'value' => 'GIF'}],
		'key params'
	);
	cmp_deeply(
		[ map { {'name'=>$_->name, 'value'=>$_->value} } $vcard_line->get_key_params('type') ],
		[ {'name' => 'TYPE', 'value' => 'GIF'} ],
		'get_key_params()',
	);
	cmp_deeply($vcard_line->as_string, "PHOTO;VALUE=URL;GIF:http://www.example.com/dir_photos/my_photo.gif\n", 'line->as_string() v2.1');
	my $vcard_line5 = Data::v::Card::Line->new(
		'line'   => "TEL;WORK;VOICE:(111) 555-1212\n",
		'parent' => $vcard,
	);
	$vcard_line5->line_changed;
	cmp_deeply([ map { $_->{'value'} } $vcard_line5->get_key_params('type')], [ 'WORK', 'VOICE' ], 'get_key_params() multiple types 2.1');
	is($vcard_line5->as_string, "TEL;WORK;VOICE:(111) 555-1212\n", 'line->as_string() with double type 2.1');
	$vcard_line5->set_key_param('LANGUAGE' => 'de');
	$vcard_line5->rm_key_param('TYPE');
	is($vcard_line5->as_string, "TEL;LANGUAGE=de:(111) 555-1212\n", 'line->as_string() with language, no type');
	$vcard_line5->set_key_param('LANGUAGE' => 'de-at');
	$vcard_line5->set_key_param('TYPE' => ['FAX', 'VOICE']);
	is($vcard_line5->as_string, "TEL;LANGUAGE=de-at;FAX;VOICE:(111) 555-1212\n", 'line->as_string() with language update, type fax,voice');
	$vcard_line5->set_key_param('TYPE' => ['VOICE']);
	$vcard_line5->set_key_param('LANGUAGE' => undef);
	is($vcard_line5->as_string, "TEL;VOICE:(111) 555-1212\n", 'line->as_string() with voice only now');

	$vcard->set_value('VERSION' => '3.0');
	is($vcard->version, '3.0', 'vcard version now 3.0');
	is($vcard_line->version, '3.0', 'vcard version now 3.0');
	cmp_deeply($vcard_line->as_string, "PHOTO;VALUE=URL;TYPE=GIF:http://www.example.com/dir_photos/my_photo.gif\n", 'line->as_string() v3.0');
	
	my $vcard_line2 = Data::v::Card::Line->new(
		'line'   => "LABEL;TYPE=WORK;ENCODING=QUOTED-PRINTABLE:100 Waters Edge=0D=0ABaytown, LA 30314=0D=0AUnited States of America\n",
		'parent' => $vcard,
	);
	$vcard_line2->line_changed;
	is($vcard_line2->get_key_param_value('encoding'), 'QUOTED-PRINTABLE', 'get_key_param_value()');
	eq_or_diff($vcard_line2->value->as_string, "100 Waters Edge\r\nBaytown, LA 30314\r\nUnited States of America", 'QUOTED-PRINTABLE encoded value');
	is($vcard_line2->as_string, "LABEL;TYPE=WORK;ENCODING=QUOTED-PRINTABLE:100 Waters Edge=0D=0ABaytown, LA 30314=0D=0AUnited States of America\n", 'line->as_string() with encoding');
	
	my $vcard_line4 = Data::v::Card::Line->new(
		'line'   => "TEL;TYPE=WORK,VOICE:(111) 555-1212\n",
		'parent' => $vcard,
	);
	$vcard_line4->line_changed;
	cmp_deeply([ map { $_->{'value'} } $vcard_line4->get_key_params('type')], [ 'WORK', 'VOICE' ], 'get_key_params() multiple types 3.0');
	is($vcard_line4->as_string, "TEL;TYPE=WORK,VOICE:(111) 555-1212\n", 'line->as_string() with double type 3.0');
	
	
	# http://tools.ietf.org/html/rfc2426#section-3.1.2
	my $n_value = Data::v::Card::Value::Name->new('Stevenson;John;Philip,Paul;Dr.;Jr.,M.D.,A.C.P.');
	is($n_value->family_name, 'Stevenson', 'N familiname');
	is($n_value->given_name, 'John', 'N given name');
	is($n_value->additional_names, 'Philip,Paul', 'N additional names');
	is($n_value->honorific_prefixes, 'Dr.', 'N honorific prefixes');
	is($n_value->honorific_suffixes, 'Jr.,M.D.,A.C.P.', 'N honorific suffixes');
	is($n_value->as_string, 'Stevenson;John;Philip,Paul;Dr.;Jr.,M.D.,A.C.P.', 'N as_string()');
	my $n_value_2 = Data::v::Card::Value::Name->new(
		'family_name' => 'Stevenson',
		'honorific_prefixes' => 'Dr.',
	);
	is($n_value_2->as_string, 'Stevenson;;;Dr.', 'N as_string()    from new() with params');
	
	my $vcard_line6 = Data::v::Card::Line->new(
		'line'   => "N:Public;John;Quinlan;Mr.;Esq.\n",
		'parent' => $vcard,
	);
	isa_ok($vcard_line6->value, 'Data::v::Card::Value::Name', 'check vCard N value isa');
	$vcard_line6->value->additional_names(undef);
	$vcard_line6->value->honorific_suffixes(undef);
	is($vcard_line6->as_string, "N:Public;John;;Mr.\n", 'line->as_string() with N');

	# http://tools.ietf.org/html/rfc2426#section-3.2.1
	my $adr_value = Data::v::Card::Value::Adr->new(';;123 Main Street;Any Town;CA;91921-1234');
	is($adr_value->po_box, '', 'ADR po_box');
	is($adr_value->ext_address, '', 'ADR ext_address');
	is($adr_value->street, '123 Main Street', 'ADR street');
	is($adr_value->city, 'Any Town', 'ADR city');
	is($adr_value->state, 'CA', 'ADR state');
	is($adr_value->postal_code, '91921-1234', 'ADR postal_code');
	is($adr_value->country, undef, 'ADR country');
	is($adr_value->as_string, ';;123 Main Street;Any Town;CA;91921-1234', 'ADR as_string()');
	my $adr_value_2 = Data::v::Card::Value::Adr->new(
		'country'     => 'Austria',
		'po_box'      => 'Box 123',
		'ext_address' => 'E',
	);
	is($adr_value_2->as_string, 'Box 123;E;;;;;Austria', 'ADR as_string()    from new() with params');
	
	my $vcard_line7 = Data::v::Card::Line->new(
		'line'   => "ADR;TYPE=dom,home,postal,parcel:;;123 Main Street;Any Town;CA;91921-1234\n",
		'parent' => $vcard,
	);
	isa_ok($vcard_line7->value, 'Data::v::Card::Value::Adr', 'check vCard ADR value isa');
	$vcard_line7->value->country('USA');
	is($vcard_line7->as_string, "ADR;TYPE=dom,home,postal,parcel:;;123 Main Street;Any Town;CA;91921-1234;USA\n", 'line->as_string() with ADR');

	# parsing the whole vCard texts
	my $vdata_1 = Data::v->new->decode(wikipedia_vcard_2_1());	
	cmp_deeply([$vdata_1->keys], ['VCARD'], 'one VCARD record');
	my $vcard_2_1 = $vdata_1->get_value('VCARD');
	isa_ok($vcard_2_1, 'Data::v::Card');
	cmp_ok($vcard_2_1->get_value('VERSION'), 'eq', '2.1', 'VERSION 2.1');
	
	my $vdata_2 = Data::v->new->decode(wikipedia_vcard_3_0());	
	cmp_deeply([$vdata_2->keys], ['VCARD'], 'one VCARD record');
	my $vcard_3_0 = $vdata_2->get_value('VCARD');
	isa_ok($vcard_3_0, 'Data::v::Card');
	cmp_ok($vcard_3_0->get_value('VERSION'), 'eq', '3.0', 'VERSION 3.0');
	
	# http://tools.ietf.org/html/rfc2425#section-5.8.1 - Type names and parameter names are case insensitive
	cmp_ok($vcard_3_0->get_value('version'), 'eq', '3.0', 'VERSION 3.0 (looked up as lc)');
	
	eq_or_diff(
		$vdata_1->encode(),
		wikipedia_vcard_2_1(),
		'encode back the VCard 2.1',
	);
	eq_or_diff(
		$vdata_2->encode(),
		wikipedia_vcard_3_0(),
		'encode back the VCard 3.0',
	);
	
	cmp_ok($vcard_3_0->get_value('email'), 'eq', 'forrestgump@example.com', 'get_value() of field with a type');
	
	return 0;
}


sub wikipedia_vcard_2_1 {
	return << '__CARD__'
BEGIN:VCARD
VERSION:2.1
N:Gump;Forrest
FN:Forrest Gump
ORG:Bubba Gump Shrimp Co.
TITLE:Shrimp Man
TEL;WORK;VOICE:(111) 555-1212
TEL;HOME;VOICE:(404) 555-1212
ADR;WORK:;;100 Waters Edge;Baytown;LA;30314;United States of America
LABEL;WORK;ENCODING=QUOTED-PRINTABLE:100 Waters Edge=0D=0ABaytown, LA 30314=0D=0AUnited States of America
ADR;HOME:;;42 Plantation St.;Baytown;LA;30314;United States of America
LABEL;HOME;ENCODING=QUOTED-PRINTABLE:42 Plantation St.=0D=0ABaytown, LA 30314=0D=0AUnited States of America
EMAIL;PREF;INTERNET:forrestgump@example.com
REV:20080424T195243Z
END:VCARD
__CARD__
}

sub wikipedia_vcard_3_0 {
	return << '__CARD__'
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest
FN:Forrest Gump
ORG:Bubba Gump Shrimp Co.
TITLE:Shrimp Man
PHOTO;VALUE=URL;TYPE=GIF:http://www.example.com/dir_photos/my_photo.gif
TEL;TYPE=WORK,VOICE:(111) 555-1212
TEL;TYPE=HOME,VOICE:(404) 555-1212
ADR;TYPE=WORK:;;100 Waters Edge;Baytown;LA;30314;United States of America
LABEL;TYPE=WORK:100 Waters Edge\nBaytown, LA 30314\nUnited States of America
ADR;TYPE=HOME:;;42 Plantation St.;Baytown;LA;30314;United States of America
LABEL;TYPE=HOME:42 Plantation St.\nBaytown, LA 30314\nUnited States of America
EMAIL;TYPE=PREF,INTERNET:forrestgump@example.com
REV:20080424T195243Z
END:VCARD
__CARD__
}


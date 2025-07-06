#!/usr/bin/env perl

use strict;
use warnings;

use Data::OFN::Address;
use Data::Text::Simple;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $obj = Data::OFN::Address->new(
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

sub _text {
        my $obj = shift;

        return encode_utf8($obj->text.' ('.$obj->lang.')');
}

# Print out.
print 'Address place: '.$obj->address_place."\n";
print 'Address place code: '.$obj->address_place_code."\n";
print 'Cadastral area: '.$obj->cadastral_area."\n";
print 'Cadastral area name: '._text($obj->cadastral_area_name->[0])."\n";
print 'Conscription number: '.$obj->conscription_number."\n";
print 'Conscription number flag: '.$obj->conscription_number_flag."\n";
print 'District: '.$obj->district."\n";
print 'District name: '._text($obj->district_name->[0])."\n";
print 'Element RUIAN: '.$obj->element_ruian."\n";
print 'House number: '.$obj->house_number."\n";
print 'House number type: '.encode_utf8($obj->house_number_type)."\n";
print 'Id: '.$obj->id."\n";
print 'Municipality: '.$obj->municipality."\n";
print 'Municipality name: '._text($obj->municipality_name->[0])."\n";
print 'Municipality part: '.$obj->municipality_part."\n";
print 'Municipality part name: '._text($obj->municipality_part_name->[0])."\n";
print 'PSC: '.$obj->psc."\n";
print 'Street: '.$obj->street."\n";
print 'Street name: '._text($obj->street_name->[0])."\n";
print 'Text: '._text($obj->text->[0])."\n";
print 'VUSC: '.$obj->vusc."\n";
print 'VUSC name: '._text($obj->vusc_name->[0])."\n";

# Output:
# Address place: https://linked.cuzk.cz/resource/ruian/adresni-misto/83163832
# Address place code: 83163832
# Cadastral area: https://linked.cuzk.cz/resource/ruian/katastralni-uzemi/635448
# Cadastral area name: Fulnek (cs)
# Conscription number: 123
# Conscription number flag: a
# District: https://linked.cuzk.cz/resource/ruian/okres/3804
# District name: Nový Jičín (cs)
# Element RUIAN: https://linked.cuzk.cz/resource/ruian/parcela/91188411010
# House number: 386
# House number type: č.p.
# Id: 7
# Municipality: https://linked.cuzk.cz/resource/ruian/obec/599352
# Municipality name: Fulnek (cs)
# Municipality part: https://linked.cuzk.cz/resource/ruian/cast-obce/413551
# Municipality part name: Fulnek (cs)
# PSC: 74245
# Street: https://linked.cuzk.cz/resource/ruian/ulice/309184
# Street name: Bílovecká (cs)
# Text: Bílovecká 386, 74245 Fulnek (cs)
# VUSC: https://linked.cuzk.cz/resource/ruian/vusc/132
# VUSC name: Moravskoslezský kraj (cs)
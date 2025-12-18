#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 37;

use_ok('Data::Identifier::Util');
use_ok('Data::Identifier');

my $id = Data::Identifier->new(wellknown => 'sid');
isa_ok($id, 'Data::Identifier');

my $util = Data::Identifier::Util->new;
isa_ok($util, 'Data::Identifier::Util');

my %packed = (
    sid8        => "\33",
    sid16       => "\0\33",
    sid32       => "\0\0\0\33",
    sni8        => "\163",
    sni16       => "\0\163",
    sni32       => "\0\0\0\163",
    uuid128     => "\xf8\x7a\x38\xcb\xfd\x13\x4e\x15\x86\x6c\xe4\x99\x01\xad\xbe\xc5",
    uuidhexdash => 'f87a38cb-fd13-4e15-866c-e49901adbec5',
    uuidHEXDASH => 'F87A38CB-FD13-4E15-866C-E49901ADBEC5',
);

foreach my $key (sort keys %packed) {
    is($util->pack($key => $id), $packed{$key}, 'pack as '.$key);
    ok($util->unpack($key => $packed{$key})->eq($id), 'unpack as '.$key);
}

foreach my $variant (qw(sid sid:27 sni:115 logical:sid)) {
    ok($util->parse_sirtx($variant)->eq($id), 'parse_sirtx "'.$variant.'"');
    ok($util->parse_sirtx('['.$variant.']')->eq($id), 'parse_sirtx "'.$variant.'"');
}

my %sirtx = (
    '\''            => 'dd8e13d3-4b0f-5698-9afa-acf037584b20',
    '\'0'           => 'dd8e13d3-4b0f-5698-9afa-acf037584b20',
    'raen:5'        => Data::Identifier->new('2bffc55d-7380-454e-bd53-c5acd525d692' => 5),
    'raes:NOSYS'    => Data::Identifier->new('2bffc55d-7380-454e-bd53-c5acd525d692' => 6),
    'chat0w:5'      => Data::Identifier->new('2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a' => 5),
    'uuid:7f265548-81dc-4280-9550-1bd0aa4bf748' => '7f265548-81dc-4280-9550-1bd0aa4bf748',
    '[[uuid:8be115d2-dc2f-4a98-91e1-a6e3075cbc31]:[8be115d2-dc2f-4a98-91e1-a6e3075cbc31]]' => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31',
);

foreach my $value (sort keys %sirtx) {
    ok($util->parse_sirtx($value)->eq($sirtx{$value}), 'parse_sirtx "'.$value.'"');
}

exit 0;

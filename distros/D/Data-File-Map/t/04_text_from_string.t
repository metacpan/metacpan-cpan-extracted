#!/usr/bin/perl -w
use strict;


use Test::More tests => 4;


use_ok 'Data::File::Map';


my $map = Data::File::Map->new;
isa_ok $map, 'Data::File::Map';

$map->parse_string ( <<STRING );
<?xml version="1.0" encoding="UTF-8"?>
<map>
    <format>text</format>
    <fields>
        <field position="1.5">id</field>
        <field position="6.20">fname</field>
        <field position="26.20">lname</field>
        <field position="46.10">birthdate</field>
        <field position="56.12">phone</field>
        <field position="68.40">email</field>
    </fields>
</map>
STRING

is_deeply [$map->field_names], [qw(id fname lname birthdate phone email)], 'extracted field names';

my $record = $map->read( '0001 Barney              Rubble              1960-09-30555.555.5555brubble@flintstones.com' . "\n" );
is_deeply $record, {
    id =>'0001',
    fname => 'Barney',
    lname => 'Rubble',
    birthdate => '1960-09-30',
    phone => '555.555.5555',
    email => 'brubble@flintstones.com',
}, 'retrieved text record';


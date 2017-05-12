#!/usr/bin/perl -w
use strict;


use Test::More tests => 4;


use_ok 'Data::File::Map';


my $map = Data::File::Map->new;
isa_ok $map, 'Data::File::Map';

$map->parse_string ( <<STRING );
<?xml version="1.0" encoding="UTF-8"?>
<map>
    <format>csv</format> <!-- csv text -->
    <separator>\t</separator> <!-- regular expression -->
    <fields>
        <field>id</field>
        <field>fname</field>
        <field>lname</field>
        <field>birthdate</field>
        <field>phone</field>
        <field>email</field>
    </fields>
</map>
STRING

is_deeply [$map->field_names], [qw(id fname lname birthdate phone email)], 'extracted field names';

my $record = $map->read( join ("\t", qw(0001 Barney Rubble 1960-09-30 555.555.5555 brubble@flintstones.com) ) . "\n" );
is_deeply $record, {
    id =>'0001',
    fname => 'Barney',
    lname => 'Rubble',
    birthdate => '1960-09-30',
    phone => '555.555.5555',
    email => 'brubble@flintstones.com',
}, 'retrirved csv record';

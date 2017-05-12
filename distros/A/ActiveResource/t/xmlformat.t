#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;

use ActiveResource::Formats::XmlFormat;

my $f = "ActiveResource::Formats::XmlFormat";

my $hash = $f->decode(<<XML);
<?xml version="1.0" encoding="UTF-8"?>
<stuff>
    <id>1</id>
    <subject>lorem ipsum</subject>
    <user name="Emily Toilet Paper" id="6"/>
</stuff>
XML

is_deeply(
    $hash,
    {
        stuff => {
            id => { text => 1 },
            subject => { text => "lorem ipsum" },
            user => {
                name => "Emily Toilet Paper",
                id => 6
            }
        }
    }
);

my $attr = {
    stuff => {
        id => { text => 2 },
        subject => {text => "OHAI"}
    }
};

my $xml = $f->encode($attr);

is($xml, <<XML);
<?xml version="1.0" encoding="UTF-8"?>
<stuff>
  <id>2</id>
  <subject>OHAI</subject>
</stuff>
XML

done_testing;

#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open qw(:std :utf8);
use Benchmark qw(:all);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use DR::Msgpuck;
use Data::MessagePack;

my $sample = {
    "glossary" => {
        "title"    => "example glossary",
        "GlossDiv" => {
            "title"     => "S",
            "GlossList" => {
                "GlossEntry" => {
                    "ID"        => "SGML",
                    "SortAs"    => "SGML",
                    "GlossTerm" => "Standard Generalized Markup Language",
                    "Acronym"   => "SGML",
                    "Abbrev"    => "ISO 8879:1986",
                    "GlossDef"  => {
                        "para" =>
                            "A meta-markup language, used to ".
                            "create markup languages such as DocBook.",
                        "GlossSeeAlso" => [ "GML", "XML" ]
                    },
                    "GlossSee" => "markup"
                }
            }
        }
    }
};


use constant ITERATIONS => 10_000_000;

my $mp = Data::MessagePack->new;

print "Packing benchmark\n";
cmpthese ITERATIONS, {
    'data-messagepack'  => sub {
        $mp->pack($sample);
    },

    'dr-msgpuck' => sub {
        msgpack($sample);
    },
};


my $blob = $mp->pack($sample);

#my $blob2 = msgpack($sample);   

print "\nUn-packing benchmark\n";
cmpthese ITERATIONS, {
    'data-messagepack'  => sub {
        $mp->unpack($blob);
    },

    'dr-msgpuck' => sub {
        msgunpack($blob);
    },
};

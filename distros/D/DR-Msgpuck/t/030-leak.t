#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 4;
use Encode qw(decode encode);

use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Test::Requires', { 'Test::LeakTrace' => 0.13 };
    use_ok 'DR::Msgpuck';
}

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
            },
            Bools   => [
                DR::Msgpuck::True->new,
                DR::Msgpuck::False->new,
            ]
        }
    }
};
my $blob = msgpack $sample;

no_leaks_ok {
    my $blob = msgpack $sample;
    msgpack $sample;
};

no_leaks_ok {
    my $blob = msgunpack $blob;
    msgunpack $blob;
};



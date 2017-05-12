#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 34;
use Encode qw(decode encode);

use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Msgpuck';
}

my @tests = (
    {
        name    => 'null',
        value   => undef,
    },
    {
        name    => 'zero',
        value   => 0,
    },
    {
        name    => 'positive char',
        value   => 1,
    },
    {
        name    => 'positive char',
        value   => 127,
    },
    {
        name    => 'positive short',
        value   => 128,
    },
    {
        name    => 'positive short',
        value   => 0xFFFF,
    },
    {
        name    => 'positive int',
        value   => 0xFFFF + 1,
    },
    {
        name    => 'positive int',
        value   => 0xFFFF_FFFF,
    },
    {
        name    => 'positive long long',
        value   => 0xFFFF_FFFF + 1,
    },
    {
        name    => 'double',
        value   => 3.141926,
    },
    {
        name    => 'negative char',
        value   => -1,
    },
    {
        name    => 'negative short',
        value   => -2000,
    },
    {
        name    => 'negative int',
        value   => -200_000,
    },
    {
        name    => 'negative long long',
        value   => -200_000_000_000,
    },
    {
        name    => 'string',
        value   => 'avc',
    },
    {
        name    => 'long string',
        value   => 'avc' x 10000,
    },
    {
        name    => 'empty array',
        value   => [],
    },
    {
        name    => 'one element array',
        value   => [undef],
    },
    {
        name    => 'two element array',
        value   => [1, 'aaaaa'],
    },
    {
        name    => 'array in array',
        value   => [1, 'aaaaa', [ a => 'b' => 'c'], 'd' ],
    },
    
    {
        name    => 'empty hash',
        value   => {},
    },
    {
        name    => 'hash',
        value   => { a => 'b'},
    },
    {
        name    => 'hash',
        value   => { a => 'b', c  => 'd' },
    },
    
    {
        name    => 'hash in hash',
        value   => { a => 'b', c  => { d => 'e' } },
    },
    {
        name    => 'array in hash in hash',
        value   => { a => 'b', c  => { d => [ 1, 2, 2.56 ] } },
    },

    {
        name    => 'bool true',
        value   => DR::Msgpuck::True->new,
    },
    {
        name    => 'bool false',
        value   => DR::Msgpuck::False->new,
    },

    {
        name    => 'json example',
        value   => {
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
        }
    }

);

my @utf8_tests = (
    {
        name    => 'utf8 string',
        value   => 'привет',
    },
    {
        name    => 'utf8 in array',
        value   => [ 'привет медвед' ],
    },
    {
        name    => 'utf8 in hash value',
        value   => { a => 'привет медвед' },
    },
    {
        name    => 'utf8 in hash key and value',
        value   => { 'привет' => 'медвед' },
    },
);


for (@tests) {
    is_deeply
        DR::Msgpuck::msgunpack(DR::Msgpuck::msgpack($_->{value})),
        $_->{value},
        $_->{name};
}

note 'utf8';
{
    ok !utf8::is_utf8(DR::Msgpuck::msgpack('привет медвед')),
        'packed blob is not utf8';
    for (@utf8_tests) {
        is_deeply
            DR::Msgpuck::msgunpack_utf8(DR::Msgpuck::msgpack($_->{value})),
            $_->{value},
            $_->{name};
    }
}

use warnings;
use strict;

use Test::More tests => 24;

require_ok "Attribute::Lexical";

eval { Attribute::Lexical->import() };
like $@, qr/\AAttribute::Lexical does no default importation/;
eval { Attribute::Lexical->unimport() };
like $@, qr/\AAttribute::Lexical does no default unimportation/;

eval { Attribute::Lexical->import("SCALAR:Foo") };
like $@, qr/\Aimport list for Attribute::Lexical must alternate /;

eval { Attribute::Lexical->import(undef, sub{}) };
like $@, qr/\Aattribute name must be a string/;
eval { Attribute::Lexical->import(sub{}, sub{}) };
like $@, qr/\Aattribute name must be a string/;
eval { Attribute::Lexical->import(undef, "wibble") };
like $@, qr/\Aattribute name must be a string/;

eval { Attribute::Lexical->import("Foo", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->import("SCALAR:", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->import("SCALAR:Foo(Bar", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->import("SCALAR:1Foo", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->import("SCALAR:Foo\x{e9}Bar", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->import("SCALAR:Foo::Bar", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->import("QUUX:Foo", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->import("Foo", "wibble") };
like $@, qr/\Amalformed attribute name/;

eval { Attribute::Lexical->import("SCALAR:Foo", "wibble") };
like $@, qr/\Aattribute handler must be a subroutine/;


eval { Attribute::Lexical->unimport(undef, sub{}) };
like $@, qr/\Aattribute name must be a string/;
eval { Attribute::Lexical->unimport(sub{}, sub{}) };
like $@, qr/\Aattribute name must be a string/;
eval { Attribute::Lexical->unimport(undef, "wibble") };
like $@, qr/\Aattribute name must be a string/;

eval { Attribute::Lexical->unimport("Foo", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->unimport("SCALAR:", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->unimport("SCALAR:Foo(Bar", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->unimport("SCALAR:Foo::Bar", sub{}) };
like $@, qr/\Amalformed attribute name/;
eval { Attribute::Lexical->unimport("QUUX:Foo", sub{}) };
like $@, qr/\Amalformed attribute name/;

1;

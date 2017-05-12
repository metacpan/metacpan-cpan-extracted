#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 16;

use_ok 'Config::Settings';

my $parser = Config::Settings->new;

isa_ok $parser,'Config::Settings';

# XXX: to be replaced with an actual test when we start using options.
Config::Settings->new ({});

ok ref $parser->parse ("") eq 'HASH',"empty configuration";

ok $parser->parse ("foo")->{foo},"true assignment";

is_deeply $parser->parse ("foo 42"),{ foo => 42 },"simple assignment";

is_deeply $parser->parse ("foo { bar 42 }"),{ foo => { bar => 42 } },"scope";

is_deeply $parser->parse ("foo bar 42"),{ foo => { bar => 42 } },"deep assignment";

is_deeply $parser->parse ("foo { bar 42 }; foo baz 84"),{ foo => { bar => 42,baz => 84 } },"deep assignment merge";

is_deeply $parser->parse ("foo 42; foo 84; foo 168"),{ foo => [ 42, 84, 168 ] },"list construction";

is_deeply $parser->parse ("foo [ 42 84 168]"),{ foo => [ 42, 84, 168 ] },"list construction (experimental)";

is_deeply $parser->parse ("foo null"),{ foo => undef },"symbol resolution";

throws_ok { $parser->parse ("foo bar") } qr/No such symbol 'bar' in symbol table/,"invalid symbol resolution";

{
  my $custom_symbol_parser = Config::Settings->new (symbol_table => { foo => sub { "bar" } });

  is_deeply $custom_symbol_parser->parse ("foo foo"),{ foo => "bar" },"custom coderef symbol";
}

throws_ok { $parser->_process_value ([ 'FOO' ]) } qr/Uh oh/;

dies_ok { $parser->parse_file ("some_file_that_doesnt_exist") };

is_deeply $parser->parse_file ("t/test.settings"),{ foo => 42 },"parse_file";


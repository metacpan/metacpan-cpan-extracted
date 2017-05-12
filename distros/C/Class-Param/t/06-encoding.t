#!perl

use strict;
use warnings;

use Test::More;

plan tests => 21;

use_ok( 'Class::Param'                     );
use_ok( 'Class::Param::Encoding'           );
can_ok( 'Class::Param::Encoding', 'get'    );
can_ok( 'Class::Param::Encoding', 'set'    );
can_ok( 'Class::Param::Encoding', 'add'    );
can_ok( 'Class::Param::Encoding', 'has'    );
can_ok( 'Class::Param::Encoding', 'clear'  );
can_ok( 'Class::Param::Encoding', 'names'  );
can_ok( 'Class::Param::Encoding', 'new'    );
can_ok( 'Class::Param::Encoding', 'param'  );
can_ok( 'Class::Param::Encoding', 'remove' );

my $params = {
    A => "\xE2\x98\xBA",
    B => "\xE2\x98\xB9",
    C => [ "\xE2\x98\xBA", "\xE2\x98\xB9" ],
    D => "\x{263A}"
};

isa_ok      my $p1 = Class::Param->new($params),       'Class::Param',           'Class::Param->new constructs a new instance';
isa_ok      my $p2 = Class::Param::Encoding->new($p1), 'Class::Param::Encoding', 'Class::Param::Encoding->new constructs a new instance';

is          $p2->get('A'),            "\x{263A}",                                '->get    A: returns right decoded value';
is          $p2->param('A'),          "\x{263A}",                                '->param  A: returns right decoded value';
is          $p2->get('B'),            "\x{2639}",                                '->get    B: returns right decoded value';
is          $p2->param('B'),          "\x{2639}",                                '->param  B: returns right decoded value';
is_deeply   $p2->get('C'),            [ "\x{263A}", "\x{2639}" ],                '->get    C: returns right decoded values';
is_deeply   [ $p2->param('C') ],      [ "\x{263A}", "\x{2639}" ],                '->param  C: returns right decoded values';
is          $p2->get('D'),            "\x{263A}",                                '->get    D: returns right decoded value';
is          $p2->param('D'),          "\x{263A}",                                '->param  D: returns right decoded value';

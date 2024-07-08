#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use v5.20;

use CodeGen::Cpppp::Enum;

subtest values_init => sub {
   my $e= CodeGen::Cpppp::Enum->new(values => [qw(
      One
      Two
      Three
   )]);
   is( [$e->values],
      [
         [ One => 0 ],
         [ Two => 1 ],
         [ Three => 2 ],
      ],
      'Start at 0'
   );
   $e->values([ One => 1 ], 'Two', 'Three');
   is( [$e->values],
      [
         [ One => 1 ],
         [ Two => 2 ],
         [ Three => 3 ],
      ],
      'Start from 1'
   );
   $e->values('Zero','One',[ Four => 4 ],'Five');
   is( [$e->values],
      [
         [ Zero => 0 ],
         [ One => 1 ],
         [ Four => 4 ],
         [ Five => 5 ],
      ],
      'Reset middle of list'
   );
};

subtest increment_expressions => sub {
   my $e= CodeGen::Cpppp::Enum->new;
   $e->values([
      A => '((65 + 0))',
      qw( B C )
   ]);
   is( [$e->values],
      [
         [ A => '((65 + 0))' ],
         [ B => '((65 + 1))' ],
         [ C => '((65 + 2))' ],
      ],
      'Simple addition in parens'
   );
   $e->values([
      A => 'X -  2',
      qw( B C D )
   ]);
   is( [$e->values],
      [
         [ A => 'X -  2' ],
         [ B => 'X + -1' ],
         [ C => 'X +  0' ],
         [ D => 'X +  1' ],
      ],
      'Increment from subtraction'
   );
};

subtest generate_macros => sub {
   my $e= CodeGen::Cpppp::Enum->new(
      values => [qw( A B C )],
      prefix => 'THING_',
   );
   is( [ $e->_generate_declaration_macros({}) ],
      [ "#define THING_A 0",
        "#define THING_B 1",
        "#define THING_C 2", ]
   );
};

subtest generate_table => sub {
   my $e= CodeGen::Cpppp::Enum->new(
      values => [qw( A B C XX )],
      prefix => 'THING_',
   );
   is( [ $e->_generate_enum_table({}) ],
      [ "const struct { const char *name; const int value; }",
        "   thing_value_table[] = {",
        '      { "THING_A",  THING_A },',
        '      { "THING_B",  THING_B },',
        '      { "THING_C",  THING_C },',
        '      { "THING_XX", THING_XX }',
        "   };",
      ]
   );
};

subtest generate_value_lookup => sub {
   my $e= CodeGen::Cpppp::Enum->new(
      values => [qw( A B C XX )],
      prefix => 'THING_',
   );
   is( [ $e->_generate_lookup_by_value_switch({}) ],
      [ 'switch (value) {',
        'case THING_A:  return thing_value_table[0].name;',
        'case THING_B:  return thing_value_table[1].name;',
        'case THING_C:  return thing_value_table[2].name;',
        'case THING_XX: return thing_value_table[3].name;',
        'default: return NULL;',
        '}',
      ],
   );
};

subtest generate_name_lookup => sub {
   my $e= CodeGen::Cpppp::Enum->new(
      values => [qw( A B C XX )],
      prefix => 'THING_',
   );
   is( [ $e->_generate_lookup_by_name_switch({}) ],
      [ 'int8_t test_el= 0;',
        'switch (len) {',
        'case 7:',
        "   if (str[6] < 'B') {",
        "      test_el= 0;",
        "   } else if (str[6] < 'C') {",
        "      test_el= 1;",
        "   } else {",
        "      test_el= 2;",
        "   }",
        "   break;",
        "case 8:",
        "   test_el= 3;",
        "   break;",
        "default:",
        "   return false;",
        '}',
        "if (strcmp(str, thing_value_table[test_el].name) == 0) {",
        "   if (value_out) *value_out= thing_value_table[test_el].value;",
        "   return true;",
        "}",
        "return false;",
      ]
   );
};

done_testing;

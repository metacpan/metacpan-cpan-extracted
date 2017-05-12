use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Routine;
use Test::Routine::Util;
use MooseX::Types::Moose qw/Num HashRef/;

use Data::TreeValidator::Constraints qw( required length options type );

test '"required" constraint' => sub {
    my $constraint = required;
    ok(!exception { $constraint->('Some input') },
        'non-empty string passes required constraint');

    ok(exception { $constraint->(undef) },
        'constraint does not allow undef input');

    ok(exception { $constraint->('') },
        'constraint does not allow empty string input');

    ok(!exception { $constraint->('0') },
        'constraint does allow string "0"');
};

test '"length" constraint' => sub {
  my $constraint = length(min => 4, max => 7);

  ok(exception { $constraint->(undef) },
     'constraint does not allow undef input');
  
  ok(exception { $constraint->('') },
     'constraint does not allow empty string input');

  ok(exception { $constraint->('abc') },
     '3-char string is not between 4 and 7 chars');

  ok(exception { $constraint->('abcdefghi') },
     '9-char string is not between 4 and 7 chars');

  ok(!exception { $constraint->('abcde') },
     '5-char string is between 4 and 7 chars');
};
  

test 'options constraint' => sub {
  my $constraint = options(qw(a b c d));

  ok(exception { $constraint->(undef) },
     'constraint does not allow undef input');
  
  ok(exception { $constraint->('') },
     'constraint does not allow empty string input');

  ok(exception { $constraint->('moose') },
     'moose is not a valid option');

  ok(exception { $constraint->(5) },
     '5 is not a valid option');

  ok(!exception { $constraint->('a') },
     'a is a valid option');

  ok(exception { $constraint->('ab') },
     'ab is not a valid option');
};

test 'type constraint (Num)' => sub {
  my $constraint = type(Num);

  ok(exception { $constraint->(undef) },
     'constraint does not allow undef input');
  
  ok(exception { $constraint->('') },
     'constraint does not allow empty string input');

  ok(exception { $constraint->('moose') },
     'moose is not a valid Num');

  ok(!exception { $constraint->(0) },
     '0 is a valid Num');

  ok(!exception { $constraint->(1) },
     '1 is a valid Num');

  ok(!exception { $constraint->(1.0) },
     '1.0 is a valid Num');

  ok(!exception { $constraint->("1") },
     '"1" is a valid Num');
};

test 'type constraint (HashRef)' => sub {
  my $constraint = type(HashRef);

  ok(exception { $constraint->(undef) },
     'constraint does not allow undef input');
  
  ok(exception { $constraint->('') },
     'constraint does not allow empty string input');

  ok(exception { $constraint->('moose') },
     'moose is not a valid HashRef');

  ok(exception { $constraint->((a => 'b')) },
     'hash is not a valid HashRef');

  ok(!exception { $constraint->({}) },
     'empty hashref is a valid HashRef');

  ok(!exception { $constraint->({a => 'b'}) },
     'non-empty hashref is a valid HashRef');
};

run_me;
done_testing;


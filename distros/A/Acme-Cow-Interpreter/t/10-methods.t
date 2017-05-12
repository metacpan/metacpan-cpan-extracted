#!/usr/bin/perl
#
# Author:      Peter John Acklam
# Time-stamp:  2010-05-23 09:33:48 +02:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

#########################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

########################

use Test::More tests => 18;
use Test::Output;

#use overload;           # for overload::StrVal()
#use Scalar::Util;       # for Scalar::Util::refaddr()

########################

use Acme::Cow::Interpreter;

my $file = 'examples/hello.cow';

###############################################################################

my $init_obj_data = {prog     => [ ],
                     prog_pos =>  0,
                     mem      => [0],
                     mem_pos  =>  0,
                     reg      => undef,
                    };

# These commands print the string "Hello, World!" followed by a newline.

my $cow_commands = <<'EOF';
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
Moo MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO Moo MoO MoO MoO MoO MoO
MoO MoO Moo Moo MoO MoO MoO Moo OOO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO Moo
MOo MOo MOo MOo MOo MOo MOo MOo MOo MOo MOo MOo Moo MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO Moo MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO Moo MoO MoO MoO Moo MOo MOo MOo MOo MOo MOo Moo MOo MOo MOo
MOo MOo MOo MOo MOo Moo OOO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO
MoO MoO MoO MoO Moo OOO MoO MoO MoO MoO MoO MoO MoO MoO MoO MoO Moo
EOF

# These are the numerical codes equivalent to the commands above.

my $cow_codes =
[6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 6, 6, 6, 6, 6,
 6, 6, 4, 4, 6, 6, 6, 4, 8, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4,
 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 4, 6, 6, 6, 4, 5, 5, 5, 5, 5, 5, 4, 5, 5, 5,
 5, 5, 5, 5, 5, 4, 8, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
 6, 6, 6, 6, 4, 8, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 4,   ];

###############################################################################
# new()
###############################################################################


ok( my $obj = Acme::Cow::Interpreter -> new(),
    "new() can be invoked");

is_deeply($obj, $init_obj_data,
          "new() returns the expected data structure");

###############################################################################
# parse_string() and execute()
###############################################################################

ok($obj -> parse_string($cow_commands),
   "parse_string('<Cow code>') can be invoked");

is_deeply($obj->{prog}, $cow_codes,
          "parse_string() creates the expected data structure in object");

output_is(
          sub { $obj -> execute(); },
          "Hello, World!\n",
          "",
          "execute() returns the expected STDOUT and STDERR",
        );

###############################################################################
# init()
###############################################################################

ok($obj -> init(), "init() can be invoked");

is_deeply($obj, $init_obj_data,
          "init() returns the expected object data structure");

###############################################################################
# parse_file()
###############################################################################

ok($obj -> parse_file($file),
   "parse_file('$file') can be invoked");

is_deeply($obj->{prog}, $cow_codes,
          "parse_file() creates the expected data structure in object");

output_is(
          sub { $obj -> execute(); },
          "Hello, World!\n",
          "",
          "execute() returns the expected STDOUT and STDERR",
        );

###############################################################################

my $code = <<'EOF';
MoO             increment current memory block to 1
MMM moO MMM     copy the value 1 to next memory block
MoO             increment current memory block to 2
MMM moO MMM     copy the value 2 to next memory block
MoO             increment current memory block to 3
mOo             decrement memory position
EOF

$obj -> parse_string($code) -> execute();

###############################################################################
# dump_obj()
###############################################################################

my $expected = <<'EOF';
$obj -> {prog}     = [6, 9, 2, 9, 6, 9, 2, 9, 6, 1];
$obj -> {prog_pos} = 9;
$obj -> {mem}      = [1, 2, 3];
$obj -> {mem_pos}  = 1;
$obj -> {reg}      = <undef>;
EOF

ok(my $got = $obj -> dump_obj(),
   "dump_obj() can be invoked");

ok($got eq $expected, "dump_obj() returns the expected output");

###############################################################################
# dump_mem()
###############################################################################

$expected = <<'EOF';
Memory block      2:            3
Memory block      1:            2 <<<
Memory block      0:            1

Register block:           <undef>
EOF

ok($got = $obj -> dump_mem(),
   "dump_obj() can be invoked");

ok($got eq $expected, "dump_mem() returns the expected output");

###############################################################################
# copy()
###############################################################################

ok(my $copy = $obj -> copy(),
   "dump_obj() can be invoked");

isa_ok($copy, 'Acme::Cow::Interpreter');

is_deeply($copy, $obj,
          "copy() returns the expected data structure");

SKIP: {
    eval { require Scalar::Util };

    skip "Scalar::Util not installed", 1 if $@;

    #ok(overload::StrVal($copy) ne overload::StrVal($obj),
    #   "copy() returns an object which is not the invocand object");

    ok(Scalar::Util::refaddr($copy) ne Scalar::Util::refaddr($obj),
       "copy() returns an object which is not the invocand object");
}

###############################################################################
# dump_obj()
###############################################################################

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:

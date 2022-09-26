use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Test::More;

use Text::ParseWords qw(shellwords);

use lib '.';
use t::Util;

##
## separate
##

test
    option => "-w10",
    stdin  => "0123456789" x 5,
    expect => join("\n", ("0123456789") x 5);

test
    option => "-w10 -n",
    stdin  => "0123456789" x 5,
    expect => join("", ("0123456789") x 5);

test
    option => "-w10 --separate ''",
    stdin  => "0123456789" x 5,
    expect => join("", ("0123456789") x 5);

test
    option => "-w10 --separate :",
    stdin  => "0123456789" x 5,
    expect => join(":", ("0123456789") x 5);

test
    option => "-w12 --prefix '> '",
    stdin  => '> ' . ("0123456789" x 5),
    expect => join("\n", ("> 0123456789") x 5);

test
    option => "-w7 --prefix '> ' --boundary=word",
    stdin  => '> 12345 1234567',
    expect => "> 12345\n" . ">  1234\n" . "> 567";

##
## multiple width
##

test
    option => "-w10,",
    stdin  => "0123456789" x 5,
    expect => join("\n", ("0123456789") x 1);

test
    option => "-w10,10",
    stdin  => "0123456789" x 5,
    expect => join("\n", ("0123456789") x 2);

test
    option => "-w10,10,10,10,10",
    stdin  => "0123456789" x 5,
    expect => join("\n", ("0123456789") x 5);

test
    option => "-w10,10,10,10,10,10",
    stdin  => "0123456789" x 5,
    expect => join("\n", ("0123456789") x 5);

test
    option => "-w10,10,0",
    stdin  => "0123456789" x 5,
    expect => join("\n", ("0123456789") x 2);

test
    option => "-w10,10,-1",
    stdin  => "0123456789" x 5,
    expect => join("\n", (("0123456789") x 2), join("", ("0123456789") x 3));

##
## colrm
##

test
    option => "-n --colrm 4",
    stdin  => "1234567890",
    expect => "123";

test
    option => "-n --colrm 4 7",
    stdin  => "1234567890",
    expect => "123890";

done_testing;

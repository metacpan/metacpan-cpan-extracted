use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Test::More;
use open IO => ':utf8', ':std';

use lib '.';
use t::Util;

##
## expand
##

test
    option => "",
    stdin  => "1234\t90",
    expect => "1234    90";

test
    option => "",
    stdin  => "1234\t90\n1234\t90\n",
    expect => "1234    90\n1234    90\n";

test
    option => "-z",
    stdin  => "1234\t90\n1234\t90\n",
    expect => "1234    90\n1234    90\n";

test
    option => "--tabstyle=shade",
    stdin  => "1234\t90",
    expect => "1234▒░░░90";

test
    option => "--tabstyle=squat-arrow,middle-dot",
    stdin  => "1234\t90",
    expect => "1234➧···90";

test
    option => "--tabstyle=shade --tabstop=4",
    stdin  => "1\t567890",
    expect => "1▒░░567890";

test
    option => "--tabstyle=shade -4",
    stdin  => "1\t567890",
    expect => "1▒░░567890";

done_testing;

# -*- Mode: Python -*-

#
# --- [ A port of the calculator example in Stroustrup's ]--------------
#

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

use strict
use warnings

use vars qw($cin $curr_tok $number_value $string_value %table)

use constant NAME   => 0
use constant NUMBER => 1
use constant STOP   => 2   # END is a Perl keyword
use constant PLUS   => '+'
use constant MINUS  => '-'
use constant MUL    => '*'
use constant DIV    => '/'
use constant PRINT  => ';'
use constant ASSIGN => '='
use constant LP     => '('
use constant RP     => ')'

%table = (pi => 3.1415926535897932385,
          e  => 2.7182818284590452354)

$curr_tok = PRINT

sub main:
    $cin = shift
    while $cin ne '':
        get_token()
        last if $curr_tok eq STOP
        next if $curr_tok eq PRINT
        return expr(0)

sub expr:
    my $get = shift
    my $left = term($get)
    while:
        $left += term(1), last if $curr_tok eq PLUS
        $left -= term(1), last if $curr_tok eq MINUS
        return $left

sub term:
    my $get = shift
    my $left = prim($get)
    while:
        $left *= prim(1), last if $curr_tok eq MUL
        if $curr_tok eq DIV:
            if my $d = prim(1):
                $left *= $d**(-1) # Filter::Simple eated too much with conventional notation
                last
            die
        return $left

sub prim:
    my $get = shift
    get_token() if $get

    if $curr_tok eq NUMBER:
        my $v = $number_value
        get_token()
        return $v
    if $curr_tok eq NAME:
        my $v = $table{$string_value}
        $v = expr(1) if get_token() eq ASSIGN
        return $v
    if $curr_tok eq MINUS:
        return -prim(1)
    if $curr_tok eq LP:
        my $e = expr(1)
        die if $curr_tok ne RP
        get_token()          # eat closing paren
        return $e
    die

# This incorpores the improvements from page 114.
sub get_token:
    $cin =~ s/^[ \t]+//
    return $curr_tok = STOP if $cin eq ''
    $cin =~ s/(.)//s
    my $ch = $1
    return $curr_tok = PRINT if $ch =~ tr/;\n//
    return $curr_tok = $ch if $ch =~ tr/*\/+()=-//
    if $ch =~ tr/0-9.//:
        $number_value = $ch
        $number_value .= $1 if $cin =~ s/^([\d.]+)//
        return $curr_tok = NUMBER
    if $ch =~ tr/a-zA-Z//:
        $string_value = $ch
        $string_value .= $1 if $cin =~ s/^([a-zA-Z]+)//
        return $curr_tok = NAME
    return $curr_tok = PRINT

is main("1"), 1
is main("10"), 10
is main("1+1"), 2
is main("2*3+4"), 10
is main("3*(12+7)-8"), 49

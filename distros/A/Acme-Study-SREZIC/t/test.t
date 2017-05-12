#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

plan tests => 1;

# http://stackoverflow.com/questions/18969702/perl-strange-behaviour-on-unpack-of-floating-value

my $f = 279.117156982422;
my $got = unpack('f>', pack ('f>', $f));
cmp_ok abs($f-$got), "<", 0.000001;

__END__

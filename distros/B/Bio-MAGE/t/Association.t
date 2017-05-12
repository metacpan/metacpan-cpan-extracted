##############################
#
# ArrayDesign.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ArrayDesign.t`

##############################
# C O P Y R I G H T   N O T I C E
#  Copyright (c) 2001-2006 by:
#    * The MicroArray Gene Expression Database Society (MGED)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.



use Carp;
# use blib;
use Test::More tests => 8;

use strict;

use Bio::MAGE::Association ':CARD';

is(Bio::MAGE::Association::CARD_1, '1', 
	'CARD_1: testing full path');

is(CARD_1, '1', 
	'CARD_1: testing import');

is(Bio::MAGE::Association::CARD_0_OR_1, '0..1', 
	'CARD_0_OR_1: testing full path');

is(CARD_0_OR_1, '0..1', 
	'CARD_0_OR_1: testing import');

is(Bio::MAGE::Association::CARD_1_TO_N, '1..N', 
	'CARD_1_TO_N: testing full path');

is(CARD_1_TO_N, '1..N', 
	'CARD_1_TO_N: testing import');

is(Bio::MAGE::Association::CARD_0_TO_N, '0..N', 
	'CARD_0_TO_N: testing full path');

is(CARD_0_TO_N, '0..N', 
	'CARD_0_TO_N: testing import');


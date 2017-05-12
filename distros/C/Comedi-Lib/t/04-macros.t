#!perl
# 
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use Test::More tests => 2;
use warnings;
use strict;

use Comedi::Lib;

# (Pseudo)-Macros
my @macros = qw(
   CR_PACK
   CR_PACK_FLAGS
   CR_CHAN
   CR_RANGE
   CR_AREF
   RANGE_OFFSET
   RANGE_LENGTH
   RF_UNIT
);

can_ok('Comedi::Lib', @macros);
is(Comedi::Lib->CR_PACK(1, 0, 0), 1, 'Comedi::Lib->CR_PACK(1, 0, 0)');

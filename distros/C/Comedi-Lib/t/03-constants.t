#!perl
# 
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use Test::More tests => 3;
use warnings;
use strict;

use Comedi::Lib;

# This is only a part of the available Comedi::Lib constants
my @const = qw(
   COMEDI_MAJOR
   COMEDI_NDEVICES
   COMEDI_NDEVCONFOPTS
   COMEDI_DEVCONF_AUX_DATA3_LENGTH
   COMEDI_NAMELEN
   CR_FLAGS_MASK
   AREF_GROUND
   GPCT_RESET
   INSN_MASK_WRITE
   INSN_READ
   INSN_WRITE
   TRIG_BOGUS
   CMDF_PRIORITY
   COMEDI_EV_START
   TRIG_ANY
   SDF_BUSY
   COMEDI_SUBD_AI
   INSN_CONFIG_DIO_INPUT
   COMEDI_INPUT
   COMEDI_UNKNOWN_SUPPORT
   RF_EXTERNAL
   UNIT_volt
   COMEDI_MIN_SPEED
);

can_ok('Comedi::Lib', @const);

is(Comedi::Lib::INSN_READ, 67108864, 'Comedi::Lib::INSN_READ');
is(Comedi::Lib::INSN_WRITE, 134217729, 'Comedi::Lib::INSN_WRITE');

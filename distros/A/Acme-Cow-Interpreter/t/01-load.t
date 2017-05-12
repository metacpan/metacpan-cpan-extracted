#!/usr/bin/perl
#
# Author:      Peter John Acklam
# Time-stamp:  2010-02-28 19:48:06 +01:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

########################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

########################

use Test::More tests => 1;

BEGIN { use_ok('Acme::Cow::Interpreter'); }

diag("Testing Acme::Cow::Interpreter"
     . " $Acme::Cow::Interpreter::VERSION, Perl $], $^X");

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::PPPort;

use File::Find;

find(sub { if ($_ eq 'ppport.h') { ppport_ok; exit 0 } }, '.');

ppport_ok;

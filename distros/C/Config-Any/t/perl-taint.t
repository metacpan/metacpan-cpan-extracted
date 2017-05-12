#!perl -T
use strict;
use warnings;

do './t/53-perl.t'
  or die ($@ || $!);

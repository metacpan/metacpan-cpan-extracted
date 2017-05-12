package Activiti::Sane;
use strict;
use warnings;
use feature ();
use utf8;

sub import {
  my $pkg = caller;
  strict->import;
  warnings->import;
  feature->import(qw(:5.10));
  utf8->import;
}

1;

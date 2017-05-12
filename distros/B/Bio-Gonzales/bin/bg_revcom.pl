#!/usr/bin/env perl
# created on 2014-07-04

use warnings;
use strict;
use 5.010;
use Bio::Gonzales::Seq::IO;
use Bio::Gonzales::Seq;



while(<STDIN>) {
  chomp;
  say Bio::Gonzales::Seq::_revcom_from_string($_, 'dna');
}

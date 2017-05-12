#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use BERT;
  
BEGIN {
    eval 'use Test::Exception';
    plan skip_all => 'Test::Exception needed' if $@;
}
  
plan tests => 2;

dies_ok(sub{ encode_bert(\'something') }, 'Unsupported type');
dies_ok(sub{ decode_bert('something') }, 'Incorrect BERT');

#!/usr/bin/perl


use strict;
use warnings;
use lib qw(./ ../lib);
use MyIterator;

my $iterator=new MyIterator(filename=>'file_example.src');
while($iterator->has_next) {
  print $iterator->get_next,"\n";
}


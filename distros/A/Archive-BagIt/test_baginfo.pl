#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Archive::BagIt;
use Data::Printer;
my $textblob =<<"BLOB";
Bag-Software-Agent: bagit.py <http://github.com/edsu/bagit>
Bagging-Date: 2013-04-09
Payload-Oxum: 4.2
BLOB
my @res = Archive::BagIt::_parse_bag_info(undef, $textblob);
p(@res);
1;

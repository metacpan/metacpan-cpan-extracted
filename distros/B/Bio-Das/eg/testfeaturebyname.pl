#!/usr/bin/perl -w

use strict;
use lib '.';
use Bio::Das;

my $db = Bio::Das->new('http://www.wormbase.org/db/das'=>'elegans');
$db->debug(0);

my @segs = $db->get_feature_by_name('Locus:unc-2');
print join "\n",@segs,"\n";
1;

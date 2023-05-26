#!/usr/bin/env perl

use strict;
use warnings;

use Data::Kramerius;
use Unicode::UTF8 qw(encode_utf8);

my $obj = Data::Kramerius->new;
my $kramerius_mzk = $obj->get('mzk');

# Print out.
print 'Active: '.$kramerius_mzk->active."\n";
print 'Id: '.$kramerius_mzk->id."\n";
print 'Name: '.encode_utf8($kramerius_mzk->name)."\n";
print 'URL: '.$kramerius_mzk->url."\n";
print 'Version: '.$kramerius_mzk->version."\n";

# Output:
# Active: 1
# Id: mzk
# Name: Moravská zemská knihovna
# URL: http://kramerius.mzk.cz/
# Version: 4
#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 2;

# Test set 1 -- can we load the library?
BEGIN { use_ok('Data::Pageset::Render'); }

# Test set 2 -- create client with ordered list of arguements
my $pager = Data::Pageset::Render->new( {
        total_entries       => 100,
        entries_per_page    => 10,
        link_format         => '%a ',
        current_link_format => '[%a] ',
} );
ok $pager, "Created new Data::Pageset::Render";

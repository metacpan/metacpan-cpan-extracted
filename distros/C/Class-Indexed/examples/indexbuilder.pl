#!/usr/bin/perl -w

use strict;

use Class::Indexed;

my %options = (database=>'testclass',host=>'localhost',username=>'testclass', password=>'foo');
my $built_tables = Class::Indexed->build_index_tables( %options );

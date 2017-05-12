#!/usr/bin/perl
use lib qw(./t blib/lib);
use strict;
no warnings;
use Test::More qw(no_plan);
 
use Bio::ConnectDots::DotQuery;
use Bio::ConnectDots::Dot;


# test constructor
my $dotQuery = new Bio::ConnectDots::DotQuery (-input=>'in', 
													-outputs=>'out', 
													-constraints=>'');												
is(ref($dotQuery), 'Bio::ConnectDots::DotQuery', 'testing DotQuery constructor');
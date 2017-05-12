#!/usr/bin/perl
use lib qw(./t blib/lib);
use strict;
no warnings;
use Test::More qw(no_plan);

use Bio::ConnectDots::Dot;
use Bio::ConnectDots::Connector;

# test constructor
my $dot = new Bio::ConnectDots::Dot;
is(ref($dot), 'Bio::ConnectDots::Dot', 'calling Dot constructor');

# test connectors()
my $connector = new Bio::ConnectDots::Connector;
my $ret = $dot->connectors($connector);
isnt($ret, undef, 'adding connector with connectors()');

my $noAdd = $dot->connectors();
isnt($noAdd, undef, 'accessing connectors with connectors()');

# test put()
$dot = new Bio::ConnectDots::Dot;
$dot->put($connector);
my $put_ret = $dot->connectors();
isnt($put_ret, undef, 'adding connector with put()');

1;
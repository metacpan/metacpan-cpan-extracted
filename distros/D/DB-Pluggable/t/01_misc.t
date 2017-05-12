#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 1;
use DB::Pluggable;
my $handler = DB::Pluggable->new->init_from_config(\<<EOINI);
[BreakOnTestNumber]

[TypeAhead]
type = {l
type = c
ifenv = DBTYPEAHEAD

[DataPrinter]
EOINI
isa_ok($handler, 'DB::Pluggable');

# hm, it's a bit difficult to test deep debugger magic...

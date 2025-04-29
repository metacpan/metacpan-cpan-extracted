#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 2;
use Test::Needs 'Log::Abstraction';

BEGIN { use_ok('Config::Abstraction') }

Log::Abstraction->import();

my @messages;
my $config = Config::Abstraction->new(logger => \@messages);

diag(Data::Dumper->new([\@messages])->Dump()) if($ENV{'TEST_VERBOSE'});

cmp_ok(scalar(@messages), '>', 0, 'Logger logs messages to an array');

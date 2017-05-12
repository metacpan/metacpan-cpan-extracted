#!/usr/bin/perl

use strict;
use warnings;
use lib ( $FindBin::Bin/lib, "$FindBin::Bin/../lib" );
use My::Server;

my $server = My::Server->new;
$server->run;

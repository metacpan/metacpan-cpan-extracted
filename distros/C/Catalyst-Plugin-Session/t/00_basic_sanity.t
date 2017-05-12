#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;


my $m; BEGIN { use_ok($m = "Catalyst::Plugin::Session") }

can_ok($m, $_) for qw/sessionid session session_delete_reason/;

#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';
use AnyEvent::Sway qw(:all);

my $sway = sway();

$sway->connect->recv or die "Error connecting";
say "Connected to Sway";

my $workspaces = $sway->message(TYPE_GET_WORKSPACES)->recv;
say "Currently, you use " . @{$workspaces} . " workspaces";


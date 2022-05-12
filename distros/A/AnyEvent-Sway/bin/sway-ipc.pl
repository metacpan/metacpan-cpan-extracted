#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent::Sway ':all';

my $sway = sway();

$sway->connect->recv || die "Failed to connect to sway\n";

my $workspaces = $sway->message(TYPE_GET_WORKSPACES)->recv;
use Data::Dump qw(dump);

print dump($workspaces);
exit;

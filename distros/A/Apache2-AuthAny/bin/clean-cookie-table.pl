#!/usr/bin/perl

use strict;
use warnings;

use Apache2::AuthAny::DB ();
use Data::Dumper qw(Dumper);

my $db = Apache2::AuthAny::DB->new();

$db->cleanupCookies();

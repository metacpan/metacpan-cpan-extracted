#!/usr/bin/perl

my $r = shift;
$r->send_http_header;

local *FH;
open FH, $r->filename or die $!;
$r->send_fd(*FH);
close FH;


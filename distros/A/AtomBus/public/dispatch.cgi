#!/usr/bin/env perl
use Dancer ':syntax';
use FindBin '$RealBin';
use Plack::Runner;

set apphandler => 'PSGI';
set environment => 'development';

my $psgi = "$RealBin/../bin/app.pl";
Plack::Runner->run($psgi);

#!/usr/bin/env perl
use Dancer ':syntax';
use FindBin '$RealBin';
use Plack::Handler::FCGI;

set apphandler => 'PSGI';
set environment => 'production';

my $app = do "$RealBin/../bin/app.pl";
my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);

$server->run($app);

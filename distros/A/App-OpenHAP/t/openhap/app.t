#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

# The lead module names the distribution for PAUSE. It loads, it
# declares the package that matches the dist name, and it holds no
# code of its own. import stays out of the probe: perl 5.39 gave
# every class a UNIVERSAL::import stub.
use_ok('App::OpenHAP');

ok( !App::OpenHAP->can($_), "App::OpenHAP has no $_ method" )
    for qw(new run);

done_testing();

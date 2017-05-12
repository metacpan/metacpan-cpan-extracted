#!/usr/bin/perl -w

######################################################
#
# thanks to Vivek Gopalan for the original version 
# 
# $Id: _perl_podcoverage.t,v 1.6 2012/02/10 13:28:28 astoltzfus Exp $
#

use strict;
use warnings;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
all_pod_coverage_ok();

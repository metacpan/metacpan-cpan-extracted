#!/usr/bin/perl -w
#
# This script illustrates how Devel::GraphVizProf could be used

use strict;
use Config;
use IPC::Run qw(run);

my $perl = $Config{'perlpath'};

my($in, $out, $err);
run["$perl -I../lib -d:GraphVizProf primes_aux.pl > primes.dot; dot -Tpng primes.dot > primes.png"], \$in, \$out, \$err;



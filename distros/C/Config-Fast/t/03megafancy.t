#!/usr/bin/perl -I. -I.. -w

# 01bournesque - read the third config file, which hits all the edge cases

use strict;
use Test;

# use a BEGIN block so we print our plan before module is loaded
BEGIN { plan tests => 11 }

use FindBin;

my $conf = "$FindBin::Bin/config.cf3";

use Config::Fast;

my %cf = fastconfig($conf);

#1
ok($cf{'why-not'}, "Hooka' Brutha' Up!!");
#2
ok($cf{'999+disembodied+heads'}, q{who doesn't love late\-night \\\- horror flix?});
#3
ok($cf{'===?===?==='}, "If this works, it's official, I\\\'m a PIMP with mad \$\$");
#4
ok($cf{'1|2|3'}, "Ain't nobody that should fix ta' use \"this\"");
#5
ok($cf{'$3.50'}, 'Damn you loch ness monster!');
#6
ok($cf{'edge_case'}, "Set1");
#7
ok($cf{'set2'}, "Set1");
#8
ok($cf{'passwd'}, '`cat /etc/passwd`');
#9
ok($cf{'evalevil'}, '"Hi there"');
#10
ok($cf{'regex'}, '$4|[4-9]*(a|b)?\.raw$|\.tiger$');

my @n = keys %cf;
my $n = @n;

#final
ok($n, 13);


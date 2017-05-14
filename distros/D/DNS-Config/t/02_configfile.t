#!/usr/local/bin/perl -w

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

use DNS::Config::File;

print "1..3\n";

my $cfg = new DNS::Config::File(
	'type' => 'Bind9',
   'file' => 't/data/named.conf'
) or die "not ok 1\n";

print "ok 1\n";

$cfg->parse() or die "not ok 2\n";

print "ok 2\n";

my $config=$cfg->config();

print "ok 3\n" if(defined $config && $config);


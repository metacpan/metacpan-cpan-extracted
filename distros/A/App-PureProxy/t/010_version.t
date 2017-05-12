#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use Test::More tests => 1;

my $output = `$^X $FindBin::Bin/../script/pureproxy.pl -v`;
like $output, qr{^PureProxy/[\w.]+ (Starlight|Thrall)/[\w.]+ Plack/[\w.]+ Perl/[\w.]+ \(.*\)$}, 'pureproxy.pl -v';

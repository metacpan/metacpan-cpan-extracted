#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use warnings;
use FindBin;
use lib $FindBin::RealBin;

use IPC::Run 'run';
use Test::More 'no_plan';

use TestUtil;

my @full_script = get_full_script('org2ical');

{
    my $res = run [@full_script, '--help'], '2>', \my $stderr;
    ok !$res, 'script run failed';
    like $stderr, qr{Unknown option: help};
    like $stderr, qr{\Qorg2ical [--debug] }, 'usage';
}

{
    my $res = run [@full_script, '--version'], '>', \my $stdout;
    ok $res, 'script run ok';
    if ($stdout =~ m{org2ical ([\d\.]+)}) {
	pass 'looks like a version';
    } else {
	fail "'$stdout' does not look like a version";
    }
}

__END__

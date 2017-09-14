#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use warnings;
use FindBin;
use IPC::Run 'run';
use Test::More 'no_plan';

my $use_blib = 1;
my $org_daemon = "$FindBin::RealBin/../blib/script/org-daemon";
unless (-f $org_daemon) {
    # blib version not available, use ../bin source version
    $org_daemon = "$FindBin::RealBin/../bin/org-daemon";
    $use_blib = 0;
}

# Special handling for systems without shebang handling
my @full_script = $^O eq 'MSWin32' || !$use_blib ? ($^X, $org_daemon) : ($org_daemon);

{
    my $res = run [@full_script, '--help'], '2>', \my $stderr;
    ok !$res, 'script run failed';
    like $stderr, qr{Unknown option: help};
    like $stderr, qr{\Qorg-daemon [--debug] [--early-warning=seconds] [--early-warning-timeless=seconds] [--recheck-interval=seconds]\E\n\t\Q[--no-emacsclient-eval] [--emacsclient-cmd=...]\E\n\t\Q[--overview-widget=...] [--move-button]\E\n\t\Q[--[no-]include-timeless] [--time-fallback HH:MM]\E\n\t\Q[--ignore-tag=... ...]\E\n\t\Qorgfile ...\E}, 'usage';
}

{
    my $res = run [@full_script, '--version'], '>', \my $stdout;
    ok $res, 'script run ok';
    if ($stdout =~ m{org-daemon ([\d\.]+)}) {
	pass 'looks like a version';
    } else {
	fail "'$stdout' does not look like a version";
    }
    my $script_version = $1;
    require App::orgdaemon;
    is $App::orgdaemon::VERSION, $script_version, 'script and lib version match';
}

__END__

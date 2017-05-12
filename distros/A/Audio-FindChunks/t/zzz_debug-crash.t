#!/usr/bin/perl -w
use strict;

my @crash = 't/Audio-FindChunks.t' if unlink 'tst-run';
pop @crash and warn "crashed, but skip auto-debug:\n\tAUTOMATED_TESTING and PERL_XSCODE_DEBUG not set\n"
 unless $ENV{AUTOMATED_TESTING} or $ENV{PERL_XSCODE_DEBUG};
print "1..1\nok 1\n";

my $debugger = 'utils/auto-debug-module.pl';
$debugger = "../$debugger" if not -f $debugger and -f "../$debugger";
@ARGV = (qw(-q Audio::FindChunks), @crash);
$0 = $debugger;
do $debugger or warn "$debugger exited unexpectedly: $@";
__END__

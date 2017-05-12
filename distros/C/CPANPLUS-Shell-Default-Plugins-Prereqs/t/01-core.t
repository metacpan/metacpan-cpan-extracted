#!/usr/bin/perl -w

use strict;
use warnings;

# Try to minimize testing errors caused by Term::ReadLine on smokers
BEGIN { $ENV{PERL_RL} = 0 };

use Test::More tests => 7;
use IO::CaptureOutput qw( capture );
use CPANPLUS::Shell qw[Default];

### TODO: test the /prereqs install
# ### Use a localized site_perl, so we can test installs
# use FindBin;
# use local::lib "$FindBin::Bin/localperl";

my $shell = CPANPLUS::Shell->new;

sub test_cmd {
    my ( $cmd, $expected_stdout, $expected_stderr, $desc ) = @_;

    my ( $stdout, $stderr );
    capture {
        $shell->dispatch_on_input(
            input          => $cmd,
            noninteractive => 1
        );
    }
    \$stdout, \$stderr;

    ok( $stdout =~ $expected_stdout && $stderr =~ $expected_stderr, $desc )
      or diag "Got stdout:\n$stdout\nGot stderr:\n$stderr\n"
      . "Expected stdout: $expected_stdout\n"
      . "Expected stderr: $expected_stderr\n";
}

### Is the plugin listed
test_cmd '/plugins', qr{/prereqs}, qr{.*}, 'Plugin listed';

### Test a Build.PL module
test_cmd '/prereqs show t/build1', qr{'stuff' was not found.*Hash::Util}s,
  qr{.*}, 'Build.PL - show';
test_cmd '/prereqs list t/build1', qr{'stuff' was not found.*Hash::Util}s,
  qr{.*}, 'Build.PL - list';

### Test a Makefile.PL module
test_cmd '/prereqs show t/mm1', qr{'stuff' was not found.*Hash::Util}s,
  qr{.*}, 'Makefile.PL - show';
test_cmd '/prereqs list t/mm1', qr{'stuff' was not found.*Hash::Util}s,
  qr{.*}, 'Makefile.PL - list';

### Test a Module::Install module
test_cmd '/prereqs show t/inc1', qr{'stuff' was not found.*Hash::Util}s,
  qr{.*}, 'Module::Install - show';
test_cmd '/prereqs list t/inc1', qr{'stuff' was not found.*Hash::Util}s,
  qr{.*}, 'Module::Install - list';

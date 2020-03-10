#!/usr/bin/perl -w

use strict;
use warnings;

# Try to minimize testing errors caused by Term::ReadLine on smokers
BEGIN { $ENV{PERL_RL} = 0 };

use Test::More tests => 5;
use IO::CaptureOutput qw( capture );
use CPANPLUS::Shell qw[Default];

### TODO: test the /prereqs install
# ### Use a localized site_perl, so we can test installs
# use FindBin;
# use local::lib "$FindBin::Bin/localperl";

my $shell = CPANPLUS::Shell->new;

sub all_match{
    my ( $in, $res ) = @_;

    for my $re (@$res){
        return unless $in =~ $re;
    }
    return 1;
}

sub test_cmd {
    my ( $cmd, $expected_stdout_array, $expected_stderr_array, $desc ) = @_;

    my ( $stdout, $stderr );
    capture {
        $shell->dispatch_on_input(
            input          => $cmd,
            noninteractive => 1
        );
    }
    \$stdout, \$stderr;

    my $match_stdout = all_match($stdout, $expected_stdout_array);
    my $match_stderr = all_match($stderr, $expected_stderr_array);

    ok( $match_stdout && $match_stderr, $desc )
      or diag "Got stdout:\n$stdout\nGot stderr:\n'$stderr'\n"
      . "Expected stdout: " . join(',', @$expected_stdout_array) . "\n"
      . "Expected stderr: " . join(',', @$expected_stderr_array) . "\n";
}

### Is the plugin listed
test_cmd '/plugins', [qr{/prereqs}m], [qr{^$}], 'Plugin listed';

### Test a Build.PL module
# FIXME: not working at the moment, not a problem with the module
# test_cmd '/prereqs show t/build1',
#   [qr{'stuff' was not found}, qr{Hash::Util}],
#   [qr{.*}],
#   'Build.PL - show';
# test_cmd '/prereqs list t/build1',
#   [qr{'stuff' was not found}, qr{Hash::Util}],
#   [qr{.*}],
#   'Build.PL - list';

### Test a Makefile.PL module
test_cmd '/prereqs show t/mm1',
  [qr{'stuff' was not found}, qr{Hash::Util}],
  [qr{.*}],
  'Makefile.PL - show';
test_cmd '/prereqs list t/mm1',
  [qr{'stuff' was not found}, qr{Hash::Util}],
  [qr{.*}],
  'Makefile.PL - list';

### Test a Module::Install module
test_cmd '/prereqs show t/inc1',
  [qr{'stuff' was not found}, qr{Hash::Util}],
  [qr{.*}],
  'Module::Install - show';
test_cmd '/prereqs list t/inc1',
  [qr{'stuff' was not found}, qr{Hash::Util}],
  [qr{.*}],
  'Module::Install - list';

#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec;

# Test the CLI binary exists and has correct structure

my $bin = File::Spec->catfile('bin', 'acme_claude_shell');

# Check file exists
ok(-f $bin, 'CLI binary exists');
ok(-r $bin, 'CLI binary is readable');

# Check it starts with shebang
open my $fh, '<', $bin or die "Cannot open $bin: $!";
my $first_line = <$fh>;
close $fh;

like($first_line, qr/^#!/, 'Starts with shebang');
like($first_line, qr/perl/, 'Uses perl interpreter');

# Check syntax by compiling (but not running)
subtest 'Syntax check' => sub {
    plan tests => 1;

    my $output = `$^X -Ilib -c $bin 2>&1`;
    like($output, qr/syntax OK/i, 'CLI binary has valid syntax');
};

# Test --help option (should not require API key)
subtest 'Help option' => sub {
    plan tests => 3;

    # Run with --help and capture output
    my $output = `$^X -Ilib $bin --help 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, '--help exits with 0');
    like($output, qr/Acme::Claude::Shell/i, 'Help mentions module name');
    like($output, qr/--dry-run|--command/i, 'Help shows options');
};

# Test --version option
subtest 'Version option' => sub {
    plan tests => 2;

    my $output = `$^X -Ilib $bin --version 2>&1`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, '--version exits with 0');
    like($output, qr/\d+\.\d+/, 'Version output contains version number');
};

done_testing();

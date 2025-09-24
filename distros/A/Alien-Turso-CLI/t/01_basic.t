use strict;
use warnings;
use Test::More 0.98;

# Skip this test in environments where alien hasn't been built yet
plan skip_all => "Skipping in environments without built alien" 
    unless $ENV{ALIEN_TURSO_CLI_TEST} || -d 'blib';

use Alien::Turso::CLI;

# Test that the module can be loaded
isa_ok(Alien::Turso::CLI->new, 'Alien::Turso::CLI');

# Test that turso binary is available
my $exe = Alien::Turso::CLI->bin_dir . '/turso';
ok(-f $exe, "turso executable exists at $exe");
ok(-x $exe, "turso executable is executable");

# Test that we can run turso --version
my $version_output = `$exe --version 2>&1`;
my $exit_code = $? >> 8;
is($exit_code, 0, "turso --version command succeeds");
like($version_output, qr/turso version/i, "version output contains 'turso version'");

done_testing;
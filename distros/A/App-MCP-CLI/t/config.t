#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::MaybeXS;
use lib 't/lib';
use TestUtil qw(write_config);
use App::MCP::CLI::Config qw(load_config resolve_server_cmd);

# The resolver reports what it resolved on STDERR; keep test output clean.
sub quiet(&) {
    my ($code) = @_;
    open my $saved, '>&', \*STDERR or die;
    open STDERR, '>', File::Spec->devnull or die;
    my @r = eval { wantarray ? $code->() : scalar $code->() };
    my $err = $@;
    open STDERR, '>&', $saved or die;
    die $err if $err;
    return wantarray ? @r : $r[0];
}

my $one = { mcpServers => { solo => { command => 'perl', args => ['a.pl', '-x'] } } };
my ($cmd, $url, $env) = quiet { resolve_server_cmd($one, 'solo') };
is_deeply($cmd, ['perl', 'a.pl', '-x'], 'command and args are combined');
is($url, undef, 'no url for stdio');
is_deeply($env, {}, 'empty env by default');

($cmd) = quiet { resolve_server_cmd($one, undef) };
is_deeply($cmd, ['perl', 'a.pl', '-x'], 'the only configured server is the default');

my $two = { mcpServers => { a => { command => 'x' }, b => { command => 'y' } } };
eval { quiet { resolve_server_cmd($two, undef) } };
like($@, qr/No server specified.*a, b/s, 'several servers and no choice is an error that lists them');

eval { quiet { resolve_server_cmd(undef, undef) } };
like($@, qr/No server specified/, 'no config and no choice is an error');

eval { quiet { resolve_server_cmd({ mcpServers => { s => { transport => 'sse' } } }, 's') } };
like($@, qr/transport 'sse' but no 'url'/, 'transport sse without url is rejected');

eval { quiet { resolve_server_cmd({ mcpServers => { s => {} } }, 's') } };
like($@, qr/neither a 'command' nor a 'url'/, 'an empty descriptor is rejected');

($cmd, $url) = quiet { resolve_server_cmd({ mcpServers => { r => { url => 'http://h/sse' } } }, 'r') };
is($url, 'http://h/sse', 'url descriptor is SSE');
is($cmd, undef, 'no command for SSE');

# env must not leak into this process or between servers
my $envcfg = { mcpServers => {
    a => { command => 'x', env => { MCPCLI_TEST_SECRET => 'one' } },
    b => { command => 'y' },
} };
my (undef, undef, $env_a) = quiet { resolve_server_cmd($envcfg, 'a') };
my (undef, undef, $env_b) = quiet { resolve_server_cmd($envcfg, 'b') };
is_deeply($env_a, { MCPCLI_TEST_SECRET => 'one' }, 'env is returned for the server that defines it');
is_deeply($env_b, {}, 'other servers get no env');
ok(!exists $ENV{MCPCLI_TEST_SECRET}, 'the process environment is untouched');

($cmd, $url) = quiet { resolve_server_cmd(undef, 'https://example.com/sse') };
is($url, 'https://example.com/sse', 'a URL argument selects SSE');

($cmd) = quiet { resolve_server_cmd(undef, 't/lib/mock_stdio.pl') };
is_deeply($cmd, [$^X, 't/lib/mock_stdio.pl'], 'an existing .pl file runs with this perl');

($cmd) = quiet { resolve_server_cmd(undef, 'node  server.js') };
is_deeply($cmd, ['node', 'server.js'], 'anything else is split on whitespace');

# load_config
my $path = write_config({ s => { command => 'x' } }, confirmTools => JSON::MaybeXS::false());
my $cfg  = quiet { load_config($path) };
is(ref $cfg->{mcpServers}, 'HASH', 'a valid config is loaded');

eval { load_config('/definitely/not/here.json') };
like($@, qr/Config file not found/, 'a missing explicit config is an error');

my $dir = tempdir(CLEANUP => 1);
my $bad = File::Spec->catfile($dir, 'bad.json');
open my $fh, '>', $bad or die; print {$fh} '{ not json'; close $fh;
eval { quiet { load_config($bad) } };
like($@, qr/Failed to parse config/, 'invalid JSON in an explicit config is an error');

done_testing;

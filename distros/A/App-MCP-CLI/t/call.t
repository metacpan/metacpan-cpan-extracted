#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use lib 't/lib';
use TestUtil qw(ROOT free_port wait_port start_bg stop_bg run_cli write_config mock_stdio_cmd);
use App::MCP::CLI::Command::call;

# argument typing (unit)
{
    my $c = \&App::MCP::CLI::Command::call::_coerce_value;
    is($c->('007',  { type => 'string' }),  '007',  'string keeps leading zeros');
    is($c->('1.0',  { type => 'string' }),  '1.0',  'string keeps trailing zero');
    is($c->('42',   { type => 'integer' }), 42,     'integer');
    is($c->('-3.5', { type => 'number' }),  -3.5,   'number');
    is($c->('abc',  { type => 'number' }),  'abc',  'invalid number is passed through for the server to reject');
    ok($c->('yes',   { type => 'boolean' }), 'boolean yes');
    ok(!$c->('false', { type => 'boolean' }), 'boolean false');
    is_deeply($c->('[1,2]',    { type => 'array' }),  [1, 2],    'array is parsed as JSON');
    is_deeply($c->('{"a":1}', { type => 'object' }), { a => 1 }, 'object is parsed as JSON');
    is($c->('7',   { type => ['null', 'integer'] }), 7, 'nullable type');
    is($c->('12',  undef),                           12, 'unknown type: plain number');
    is($c->('007', undef),                           '007', 'unknown type: leading zeros stay a string');
    is($c->('12345678901234567890', undef), '12345678901234567890', 'huge integers are not rounded');
}

my $stdio_cfg = write_config({ mock => { command => $^X, args => [ ROOT . '/t/lib/mock_stdio.pl' ] } });

sub mcpcli { my ($args, %o) = @_; return run_cli(args => $args, %o) }

# call (stdio)
{
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $stdio_cfg, '--server', 'mock', 'a=2', 'b=3']);
    is($rc,  0,         'call succeeds');
    is($out, "sum=5\n", 'STDOUT contains only the tool result');
    like($err, qr/Calling tool 'add_numbers'/, 'progress goes to STDERR');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $stdio_cfg, 'a=2', 'b=3']);
    is($out, "sum=5\n", '--server may be omitted when one server is configured');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $stdio_cfg, 'a=2']);
    is($rc, 1, 'a missing required argument fails');
    like($err, qr/Missing required argument\(s\): b/, '... and says which');
    is($out, '', '... without output');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'fail', '--config', $stdio_cfg, 'x=1']);
    is($rc, 1, 'a tool result with isError exits 1');
    like($err, qr/Error: boom/, '... and the text goes to STDERR');
    is($out, '', '... not to STDOUT');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'img', '--config', $stdio_cfg, 'x=1']);
    is($rc, 0, 'image result is not an error');
    like($out, qr{\[image: image/png, 4 bytes base64}, 'image block is shown as a placeholder');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'nosuchtool', '--config', $stdio_cfg, 'x=1']);
    is($rc, 1, 'an unknown tool exits 1');
    like($err, qr/Tool 'nosuchtool' not found on server\. Available: add_numbers/, '... and lists the real tools');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'echo_string', '--config', $stdio_cfg, 's=007']);
    is($out, "s=007\n", 'a string argument keeps its leading zeros');
    ($out) = mcpcli(['call', 'bool_flag', '--config', $stdio_cfg, 'flag=yes']);
    is($out, "flag=true\n", 'boolean arguments are typed from the schema');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $stdio_cfg, 'oops']);
    isnt($rc, 0, 'a malformed argument is a usage error');
    like($err, qr/Invalid argument 'oops': expected key=value/, '... with an explanation');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', '/no/such/file.json', 'a=1', 'b=2']);
    is($rc, 1, 'a missing --config file exits 1');
    like($err, qr/Config file not found/, '... with a clear message');
}
{
    my $two = write_config({ a => { command => 'x' }, b => { command => 'y' } });
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $two, 'a=1', 'b=2']);
    is($rc, 1, 'no --server with several configured servers exits 1');
    like($err, qr/No server specified.*a, b/s, '... and lists them');
}
{
    my $bad = write_config({ broken => { transport => 'sse' } });
    my ($out, $err, $rc) = mcpcli(['list', '--config', $bad]);
    is($rc, 1, 'transport sse without url exits 1');
    like($err, qr/transport 'sse' but no 'url'/, '... with a clear message');
}
{
    my $dead = write_config({ dead => { command => 'true' } });
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $dead, '--timeout', '3', 'a=1', 'b=2']);
    is($rc, 1, 'a server that exits at once gives exit 1');
    like($err, qr/closed the connection|Failed to write/, '... and a readable message (no JSON parse error)');
    unlike($err, qr/malformed JSON|at \S+ line \d+/, '... with no Perl stack trace');
}
{
    my $t0 = time;
    my ($out, $err, $rc) = mcpcli(['call', 'slow', '--config', $stdio_cfg, '--timeout', '1', 'x=1']);
    is($rc, 1, 'a silent server times out with exit 1');
    like($err, qr/Timed out waiting/, '... and says so');
    cmp_ok(time - $t0, '<', 15, '... instead of hanging');
}
{
    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $stdio_cfg],
                                  stdin => "4\n5\n");
    is($out, "sum=9\n", 'interactive prompt mode works');
    like($err, qr/Entering interactive prompt/, '... and prompts on STDERR');
}

# list / servers (tables)
SKIP: {
    skip 'Text::Table::Tiny not installed', 6 unless eval { require Text::Table::Tiny; 1 };

    my ($out, $err, $rc) = mcpcli(['list', '--config', $stdio_cfg]);
    is($rc, 0, 'list succeeds');
    like($out, qr/add_numbers.*Adds two numbers/s, 'list shows a tool');
    like($out, qr/get_env/, 'list follows pagination (tool from page two)');

    ($out, $err, $rc) = mcpcli(['servers', '--config', $stdio_cfg]);
    is($rc, 0, 'servers succeeds');
    like($out, qr/mock/, 'servers shows the server');

    ($out, $err, $rc) = mcpcli(['version']);
    like($out, qr/^mcpcli version \S+$/, 'version prints the version');
}

# call/list over SSE
{
    my $port = free_port();
    my $pid  = start_bg(cmd => [ $^X, ROOT . '/t/lib/mock_sse.pl', $port ]);
    ok(wait_port($port), 'mock SSE server is up') or BAIL_OUT('mock SSE server did not start');
    my $cfg = write_config({ sse => { url => "http://127.0.0.1:$port/sse" } });

    my ($out, $err, $rc) = mcpcli(['call', 'add_numbers', '--config', $cfg, 'a=4', 'b=5']);
    is($rc,  0,         'call works over SSE (it used to crash)');
    is($out, "sum=9\n", '... and returns the result');

    SKIP: {
        skip 'Text::Table::Tiny not installed', 2 unless eval { require Text::Table::Tiny; 1 };
        ($out, $err, $rc) = mcpcli(['list', '--config', $cfg]);
        is($rc, 0, 'list works over SSE (it used to crash)');
        like($out, qr/add_numbers/, '... and shows the tools');
    }
    stop_bg($pid);
}

done_testing;

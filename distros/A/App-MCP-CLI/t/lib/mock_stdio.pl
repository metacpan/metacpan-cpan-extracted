#!/usr/bin/perl
# Mock MCP stdio server used by the test-suite (not part of the public API).
use strict;
use warnings;
use JSON::MaybeXS;

$| = 1;
my $j = JSON::MaybeXS->new(utf8 => 1);
my $initialized = 0;

my @tools = (
    { name => 'add_numbers', description => 'Adds two numbers',
      inputSchema => { type => 'object', required => ['a', 'b'],
        properties => { a => { type => 'number' }, b => { type => 'number' } } } },
    { name => 'echo_string', description => 'Echoes a string',
      inputSchema => { type => 'object', properties => { s => { type => 'string' } } } },
    { name => 'bool_flag', description => 'Reports a boolean',
      inputSchema => { type => 'object', properties => { flag => { type => 'boolean' } } } },
    { name => 'fail',       description => 'Always reports isError', inputSchema => { type => 'object' } },
    { name => 'img',        description => 'Returns an image block', inputSchema => { type => 'object' } },
    { name => 'init_state', description => 'Was notifications/initialized received?', inputSchema => { type => 'object' } },
    { name => 'get_env',    description => 'Reads MOCK_VAR', inputSchema => { type => 'object' } },
    { name => 'slow',       description => 'Never answers in time', inputSchema => { type => 'object' } },
    { name => 'die',        description => 'Exits without answering', inputSchema => { type => 'object' } },
);

sub text { return { content => [ { type => 'text', text => $_[0] } ] } }

while (my $line = <STDIN>) {
    my $m = eval { $j->decode($line) } or next;
    my $method = $m->{method} // '';

    if ($method eq 'notifications/initialized') { $initialized = 1; next }
    next unless defined $m->{id};

    # Noise a real server may produce: a stray log line and a notification.
    print "this is a log line, not JSON\n";
    print $j->encode({ jsonrpc => '2.0', method => 'notifications/message',
                       params => { level => 'info', data => 'hello' } }), "\n";

    my $r = { jsonrpc => '2.0', id => $m->{id} };

    if ($method eq 'initialize') {
        $r->{result} = { protocolVersion => '2024-11-05', capabilities => { tools => {} },
                         serverInfo => { name => 'mock-stdio', version => '1' } };
    }
    elsif ($method eq 'tools/list') {
        # Two pages, to exercise nextCursor handling.
        if (($m->{params}{cursor} // '') eq 'page2') { $r->{result} = { tools => [ @tools[5 .. $#tools] ] } }
        else { $r->{result} = { tools => [ @tools[0 .. 4] ], nextCursor => 'page2' } }
    }
    elsif ($method eq 'tools/call') {
        my ($name, $a) = ($m->{params}{name}, $m->{params}{arguments} || {});
        if    ($name eq 'add_numbers') { $r->{result} = text('sum=' . ($a->{a} + $a->{b})) }
        elsif ($name eq 'echo_string') { $r->{result} = text('s=' . ($a->{s} // '')) }
        elsif ($name eq 'bool_flag')   { $r->{result} = text('flag=' . ($a->{flag} ? 'true' : 'false')) }
        elsif ($name eq 'fail')        { $r->{result} = { isError => JSON::MaybeXS::true(), content => [ { type => 'text', text => 'boom' } ] } }
        elsif ($name eq 'img')         { $r->{result} = { content => [ { type => 'image', data => 'QUJD', mimeType => 'image/png' } ] } }
        elsif ($name eq 'init_state')  { $r->{result} = text("initialized=$initialized") }
        elsif ($name eq 'get_env')     { $r->{result} = text('MOCK_VAR=' . ($ENV{MOCK_VAR} // 'unset')) }
        elsif ($name eq 'slow')        { sleep 30; next }
        elsif ($name eq 'die')         { exit 0 }
        else { $r->{error} = { code => -32602, message => "Unknown tool: $name" } }
    }
    else { $r->{error} = { code => -32601, message => "Method not found: $method" } }

    print $j->encode($r), "\n";
}

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use lib 't/lib';
use TestUtil qw(ROOT free_port wait_port start_bg stop_bg run_cli write_config);

plan skip_all => 'HTTP::Daemon is needed for the fake Ollama server'
    unless eval { require HTTP::Daemon; 1 };

my $port = free_port();
my $pid  = start_bg(cmd => [ $^X, ROOT . '/t/lib/mock_ollama.pl', $port ]);
ok(wait_port($port), 'fake Ollama is up') or BAIL_OUT('fake Ollama did not start');

my $cfg = write_config(
    { mock => { command => $^X, args => [ ROOT . '/t/lib/mock_stdio.pl' ] } },
    confirmTools => JSON::MaybeXS::false(),
);

sub chat {
    my (@questions) = @_;
    my ($out, $err, $rc) = run_cli(
        args  => [ 'chat', '--config', $cfg, '--server', 'mock' ],
        stdin => join('', map { "$_\n" } @questions, 'exit'),
        env   => { OLLAMA_HOST => "127.0.0.1:$port" },
    );
    $out =~ s/\e\[[0-9;]*m//g;    # strip colours
    return ($out, $err, $rc);
}

{
    my ($out, $err, $rc) = chat('add 2 and 3');
    is($rc, 0, 'a normal tool round trip exits 0');
    like($out, qr/Found 9 tool\(s\)/, 'tools from both pages are loaded');
    like($out, qr/Response: SUMMARY:sum=5/, 'tool result is summarised by the model');
    like($out, qr/Session Closed/, 'session ends cleanly');
}
{
    my ($out, $err, $rc) = chat('array please');
    is($rc, 0, 'valid JSON that is not an object does not crash chat');
    like($out, qr/Response: \[1,2,3\]/, '... it is shown as a plain reply');
}
{
    my ($out, $err, $rc) = chat('empty please');
    is($rc, 0, 'a model reply without text does not crash chat');
    like($out, qr/Response: .*(empty or unreadable|Failed to parse)/, '... and says so');
}
{
    my ($out, $err, $rc) = chat('nosuch tool');
    is($rc, 0, 'a request for a non-existent tool does not crash chat');
    like($out, qr/tool that does not exist \('nope'\)/, '... it is refused with an explanation');
}
{
    my ($out, $err, $rc) = chat('noargs please');
    is($rc, 0, 'a tool call without "arguments" does not crash chat');
    like($out, qr/Response: SUMMARY:initialized=1/, '... it is called with empty arguments');
}
{
    my ($out, $err, $rc) = chat('fail please', 'add 2 and 3');
    is($rc, 0, 'a failing tool does not end the session');
    like($out, qr/Tool error: boom/, '... the error is reported');
    like($out, qr/Response: SUMMARY:sum=5/, '... and the next question still works');
}
{
    my ($out, $err, $rc) = chat('just talk');
    like($out, qr/Response: plain answer/, 'a plain reply is shown');
}
{
    my $dead = write_config({ dead => { command => 'true' } });
    my ($out, $err, $rc) = run_cli(args => [ 'chat', '--config', $dead, '--server', 'dead', '--timeout', '3' ],
                                   stdin => "exit\n", env => { OLLAMA_HOST => "127.0.0.1:$port" });
    is($rc, 1, 'chat against a dead server exits 1');
    like($err, qr/^Error: /m, '... with a readable error');
}

stop_bg($pid);
done_testing;

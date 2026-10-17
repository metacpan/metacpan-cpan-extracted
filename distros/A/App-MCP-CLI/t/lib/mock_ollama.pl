#!/usr/bin/perl
# Fake Ollama /api/generate used by t/chat.t: the reply depends on the question.
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Response;
use JSON::MaybeXS;

my $port = shift or die "usage: $0 PORT\n";
$SIG{TERM} = sub { exit 0 };
my $j = JSON::MaybeXS->new(utf8 => 1);
my $d = HTTP::Daemon->new(LocalAddr => '127.0.0.1', LocalPort => $port, ReuseAddr => 1) or die $!;

while (my $c = $d->accept) {
    while (my $req = $c->get_request) {
        my $body   = eval { $j->decode($req->content) } || {};
        my $prompt = $body->{prompt} // '';
        my $resp;

        if    ($prompt =~ /^The user asked:.*?raw result data:\n(.*?)\nProvide a brief/s) { $resp = "SUMMARY:$1" }
        elsif ($prompt =~ /User Question: array/)   { $resp = '[1,2,3]' }
        elsif ($prompt =~ /User Question: empty/)   { $resp = undef }
        elsif ($prompt =~ /User Question: nosuch/)  { $resp = '{"action":"call_tool","tool":"nope","arguments":{}}' }
        elsif ($prompt =~ /User Question: add/)     { $resp = '{"action":"call_tool","tool":"add_numbers","arguments":{"a":2,"b":3}}' }
        elsif ($prompt =~ /User Question: noargs/)  { $resp = '{"action":"call_tool","tool":"init_state"}' }
        elsif ($prompt =~ /User Question: fail/)    { $resp = '{"action":"call_tool","tool":"fail","arguments":{}}' }
        else                                         { $resp = '{"action":"reply","answer":"plain answer"}' }

        my $out = $j->encode({ response => $resp });
        my $r = HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], $out);
        $c->send_response($r);
    }
    $c->close;
}

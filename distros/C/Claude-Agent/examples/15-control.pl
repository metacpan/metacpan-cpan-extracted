#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;

# Drive a session through the control protocol: inspect what the CLI
# reported at startup, change the model and permission mode between
# turns, read the MCP status and context usage, and interrupt a turn.

use Claude::Agent qw(session);
use Claude::Agent::Options;

my $client = session(
    options => Claude::Agent::Options->new(
        allowed_tools   => ['Read', 'Glob', 'Grep'],
        permission_mode => 'plan',
        max_turns       => 3,
    ),
);

$client->connect('Give me a one-line summary of this directory.');

my $info = $client->server_info;
say "CLI supports ", scalar @{ $info->{commands} // [] }, " commands";
say "Output style: ", $info->{output_style} // 'default';

for my $msg ($client->receive_until_result) {
    say "Claude: ", $msg->text if $msg->isa('Claude::Agent::Message::Assistant') && length $msg->text;
    say "Result: ", $msg->result // $msg->subtype if $msg->isa('Claude::Agent::Message::Result');
}

my $status = $client->mcp_status;
say "MCP servers: ", join(', ', map { "$_->{name} ($_->{status})" } @{ $status->{mcpServers} // [] }) || 'none';

my $usage = $client->get_context_usage;
say sprintf("Context used: %s of %s tokens", $usage->{totalTokens} // '?', $usage->{maxTokens} // '?');

say "Switching to sonnet and acceptEdits";
$client->set_model('sonnet');
$client->set_permission_mode('acceptEdits');

$client->send('Now count the Perl files here.');
my $first = 1;
while (my $msg = $client->receive) {
    if ($first && $msg->isa('Claude::Agent::Message::Assistant')) {
        say "Interrupting after the first assistant message";
        $client->interrupt;
        $first = 0;
    }
    if ($msg->isa('Claude::Agent::Message::Result')) {
        say "Turn ended: ", $msg->subtype, ($msg->has_terminal_reason ? " (" . $msg->terminal_reason . ")" : '');
        last;
    }
}

$client->disconnect;

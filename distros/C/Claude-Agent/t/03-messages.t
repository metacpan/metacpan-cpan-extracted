#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Message;
use Claude::Agent::Content;

# Test UserMessage
my $user_msg = Claude::Agent::Message::User->new(
    type       => 'user',
    uuid       => 'uuid-123',
    session_id => 'session-456',
    message    => { role => 'user', content => 'Hello' },
);

isa_ok($user_msg, 'Claude::Agent::Message::User');
isa_ok($user_msg, 'Claude::Agent::Message::Base');
is($user_msg->type, 'user', 'UserMessage type is user');
is($user_msg->uuid, 'uuid-123', 'uuid correct');
is($user_msg->session_id, 'session-456', 'session_id correct');

# Test AssistantMessage
my $assistant_msg = Claude::Agent::Message::Assistant->new(
    type       => 'assistant',
    uuid       => 'uuid-789',
    session_id => 'session-456',
    message    => {
        role    => 'assistant',
        content => [
            { type => 'text', text => 'Hello there!' },
            { type => 'tool_use', id => 'tool-1', name => 'Read', input => { file => 'test.txt' } },
        ],
    },
    model => 'claude-sonnet-4-20250514',
);

isa_ok($assistant_msg, 'Claude::Agent::Message::Assistant');
is($assistant_msg->type, 'assistant', 'AssistantMessage type is assistant');
is($assistant_msg->model, 'claude-sonnet-4-20250514', 'model correct');

# Test text() helper
is($assistant_msg->text, 'Hello there!', 'text() extracts text content');

# Test content_blocks() helper - returns raw hashrefs
my @blocks = @{$assistant_msg->content_blocks};
is(scalar @blocks, 2, 'content_blocks returns 2 blocks');
is($blocks[0]->{type}, 'text', 'first block is text');
is($blocks[1]->{type}, 'tool_use', 'second block is tool_use');

# Test tool_uses() helper - returns raw hashrefs
my @tool_uses = @{$assistant_msg->tool_uses};
is(scalar @tool_uses, 1, 'tool_uses returns 1 tool use');
is($tool_uses[0]->{name}, 'Read', 'tool_use name correct');

# Test SystemMessage
my $system_msg = Claude::Agent::Message::System->new(
    type       => 'system',
    uuid       => 'uuid-sys',
    session_id => 'session-456',
    subtype    => 'init',
);

isa_ok($system_msg, 'Claude::Agent::Message::System');
is($system_msg->type, 'system', 'SystemMessage type is system');
is($system_msg->subtype, 'init', 'subtype correct');

# Test ResultMessage
my $result_msg = Claude::Agent::Message::Result->new(
    type          => 'result',
    uuid          => 'uuid-result',
    session_id    => 'session-456',
    subtype       => 'success',
    result        => 'Task completed successfully',
    duration_ms   => 1500,
    total_cost_usd => 0.05,
    num_turns     => 3,
    is_error      => 0,
    usage         => {
        input_tokens  => 100,
        output_tokens => 50,
    },
);

isa_ok($result_msg, 'Claude::Agent::Message::Result');
is($result_msg->type, 'result', 'ResultMessage type is result');
is($result_msg->subtype, 'success', 'subtype correct');
is($result_msg->result, 'Task completed successfully', 'result correct');
is($result_msg->duration_ms, 1500, 'duration_ms correct');
is($result_msg->total_cost_usd, 0.05, 'total_cost_usd correct');
is($result_msg->num_turns, 3, 'num_turns correct');
ok(!$result_msg->is_error, 'is_error correct');

# Test from_json factory method
my $json_user = {
    type       => 'user',
    uuid       => 'json-uuid',
    sessionId  => 'json-session',
    message    => { role => 'user', content => 'Test' },
};

my $parsed_user = Claude::Agent::Message->from_json($json_user);
isa_ok($parsed_user, 'Claude::Agent::Message::User');
is($parsed_user->uuid, 'json-uuid', 'from_json uuid');
is($parsed_user->session_id, 'json-session', 'from_json sessionId -> session_id');

my $json_assistant = {
    type      => 'assistant',
    uuid      => 'assist-uuid',
    sessionId => 'json-session',
    message   => {
        role    => 'assistant',
        content => [{ type => 'text', text => 'Response' }],
    },
    model => 'claude-sonnet-4-20250514',
};

my $parsed_assistant = Claude::Agent::Message->from_json($json_assistant);
isa_ok($parsed_assistant, 'Claude::Agent::Message::Assistant');
is($parsed_assistant->text, 'Response', 'from_json assistant text');

my $json_system = {
    type      => 'system',
    uuid      => 'sys-uuid',
    sessionId => 'json-session',
    subtype   => 'init',
    sessionId => 'new-session-id',
};

my $parsed_system = Claude::Agent::Message->from_json($json_system);
isa_ok($parsed_system, 'Claude::Agent::Message::System');
is($parsed_system->subtype, 'init', 'from_json system subtype');

my $json_result = {
    type         => 'result',
    uuid         => 'result-uuid',
    sessionId    => 'json-session',
    subtype      => 'success',
    result       => 'Done',
    durationMs   => 1000,
    totalCostUsd => 0.01,
    numTurns     => 1,
    isError      => 0,
};

my $parsed_result = Claude::Agent::Message->from_json($json_result);
isa_ok($parsed_result, 'Claude::Agent::Message::Result');
is($parsed_result->result, 'Done', 'from_json result');
is($parsed_result->duration_ms, 1000, 'from_json durationMs -> duration_ms');

done_testing();

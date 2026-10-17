#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use JSON::PP ();

use Claude::Agent::Message;
use Claude::Agent::Content;

subtest 'unknown keys are ignored and kept in raw' => sub {
    my $msg = Claude::Agent::Message->from_json({
        type        => 'user',
        uuid        => 'u1',
        sessionId   => 's1',
        message     => { role => 'user', content => 'hi' },
        newField    => 'surprise',
        anotherOne  => [1, 2],
    });
    isa_ok($msg, 'Claude::Agent::Message::User');
    is($msg->session_id, 's1', 'sessionId normalised');
    ok(!$msg->can('new_field'), 'no accessor for an unknown key');
    is($msg->raw->{newField}, 'surprise', 'raw keeps the original key');
    is_deeply($msg->raw->{anotherOne}, [1, 2], 'raw keeps the original value');
    is($msg->raw->{sessionId}, 's1', 'raw keeps the original casing');
};

subtest 'key order never changes the parse' => sub {
    my $ok = 1;
    for my $i (1 .. 40) {
        my $msg = Claude::Agent::Message->from_json({
            "zz$i"    => 1,
            "aa$i"    => 2,
            type      => 'user',
            message   => { role => 'user', content => 'x' },
            sessionId => 's',
            bogus     => undef,
        });
        $ok = 0 unless $msg->isa('Claude::Agent::Message::User')
            && $msg->session_id eq 's'
            && $msg->raw->{"zz$i"} == 1;
    }
    ok($ok, 'forty random key orders all parse as pairs');
};

subtest 'result fields' => sub {
    my $msg = Claude::Agent::Message->from_json({
        type              => 'result',
        subtype           => 'error_max_turns',
        uuid              => 'r1',
        session_id        => 's1',
        is_error          => JSON::PP::true,
        errors            => ['too many turns'],
        duration_ms       => 10,
        duration_api_ms   => 5,
        num_turns         => 3,
        total_cost_usd    => 0.1,
        usage             => { input_tokens => 1 },
        modelUsage        => { 'claude-x' => { inputTokens => 1 } },
        permission_denials => [],
        stop_reason       => 'end_turn',
        terminal_reason   => 'max_turns',
        api_error_status  => undef,
        user_message_uuid => 'um1',
        structured_output => undef,
    });
    isa_ok($msg, 'Claude::Agent::Message::Result');
    ok($msg->is_error, 'JSON true is_error is true');
    ok(!$msg->is_success, 'not a success');
    is_deeply($msg->errors, ['too many turns'], 'errors');
    is($msg->error_text, 'too many turns', 'error_text from errors');
    is($msg->model_usage->{'claude-x'}{inputTokens}, 1, 'modelUsage -> model_usage');
    is($msg->stop_reason, 'end_turn', 'stop_reason');
    is($msg->terminal_reason, 'max_turns', 'terminal_reason');
    is($msg->user_message_uuid, 'um1', 'user_message_uuid');
    ok(!$msg->has_api_error_status, 'JSON null is absent');
    ok(!$msg->has_structured_output, 'JSON null structured_output is absent');

    my $ok = Claude::Agent::Message->from_json({
        type => 'result', subtype => 'success', result => 'done',
        is_error => JSON::PP::false,
    });
    ok(!$ok->is_error, 'JSON false is_error is false');
    is($ok->error_text, 'done', 'error_text falls back to result');
    is(Claude::Agent::Message->from_json({ type => 'result', subtype => 'error_during_execution' })->error_text,
        'error_during_execution', 'error_text falls back to subtype');
};

subtest 'new message classes' => sub {
    my $ev = Claude::Agent::Message->from_json({
        type  => 'stream_event',
        event => { type => 'content_block_delta', delta => { type => 'text_delta', text => 'Hel' } },
        parent_tool_use_id => undef,
        session_id => 's',
    });
    isa_ok($ev, 'Claude::Agent::Message::StreamEvent');
    is($ev->event_type, 'content_block_delta', 'event_type');
    is($ev->text_delta, 'Hel', 'text_delta');
    ok(!$ev->has_parent_tool_use_id, 'null parent_tool_use_id is absent');

    my $stop = Claude::Agent::Message->from_json({ type => 'stream_event', event => { type => 'message_stop' } });
    ok(!defined $stop->text_delta, 'no text_delta on message_stop');

    my $rl = Claude::Agent::Message->from_json({
        type => 'rate_limit_event',
        rate_limit_info => { status => 'allowed', resetsAt => 123, rateLimitType => 'five_hour', utilization => 0.5 },
    });
    isa_ok($rl, 'Claude::Agent::Message::RateLimitEvent');
    is($rl->status, 'allowed', 'status');
    is($rl->resets_at, 123, 'resets_at');
    is($rl->rate_limit_type, 'five_hour', 'rate_limit_type');
    is($rl->utilization, 0.5, 'utilization');

    my $tp = Claude::Agent::Message->from_json({
        type => 'tool_progress', tool_use_id => 't1', tool_name => 'Bash', elapsed_time_seconds => 4.5,
    });
    isa_ok($tp, 'Claude::Agent::Message::ToolProgress');
    is($tp->tool_name, 'Bash', 'tool_name');
    is($tp->elapsed_time_seconds, 4.5, 'elapsed_time_seconds');

    my $hk = Claude::Agent::Message->from_json({
        type => 'system', subtype => 'hook_started', hook_event_name => 'PreToolUse', hook_name => 'x', hook_id => 'h1',
    });
    isa_ok($hk, 'Claude::Agent::Message::HookEvent');
    isa_ok($hk, 'Claude::Agent::Message::System');
    is($hk->hook_event_name, 'PreToolUse', 'hook_event_name');
    is($hk->subtype, 'hook_started', 'subtype');

    my $init = Claude::Agent::Message->from_json({
        type => 'system', subtype => 'init', apiKeySource => 'none', permissionMode => 'plan',
        mcp_servers => [{ name => 'x', status => 'connected' }], capabilities => ['interrupt_receipt_v1'],
    });
    isa_ok($init, 'Claude::Agent::Message::System');
    ok(!$init->isa('Claude::Agent::Message::HookEvent'), 'init is not a HookEvent');
    is($init->api_key_source, 'none', 'apiKeySource -> api_key_source');
    is($init->permission_mode, 'plan', 'permissionMode -> permission_mode');
    is($init->mcp_servers->[0]{status}, 'connected', 'mcp_servers array');
    is_deeply($init->raw->{capabilities}, ['interrupt_receipt_v1'], 'undeclared field in raw');

    my $state = Claude::Agent::Message->from_json({ type => 'system', subtype => 'session_state_changed', state => 'idle' });
    is($state->state, 'idle', 'session state');

    for my $type (qw(tool_use_summary prompt_suggestion conversation_reset keep_alive something_new)) {
        my $m = Claude::Agent::Message->from_json({ type => $type, payload => 1 });
        is(ref $m, 'Claude::Agent::Message::Base', "$type is a Base");
        is($m->type, $type, "$type keeps its type");
        is($m->raw->{payload}, 1, "$type payload in raw");
    }
};

subtest 'assistant helpers' => sub {
    my $msg = Claude::Agent::Message->from_json({
        type => 'assistant', uuid => 'a1', session_id => 's', model => 'claude-x',
        message => {
            id => 'msg_1', role => 'assistant', stop_reason => 'tool_use',
            usage => { input_tokens => 3, output_tokens => 4 },
            content => [
                { type => 'text', text => 'Hi', cache_control => { type => 'ephemeral' } },
                { type => 'tool_use', id => 't1', name => 'Read', input => { file_path => 'x' }, extra => 1 },
                { type => 'server_tool_use', id => 'srv', name => 'web_search', input => {} },
            ],
        },
        error => undef,
    });
    is($msg->message_id, 'msg_1', 'message_id');
    is($msg->stop_reason, 'tool_use', 'stop_reason');
    is($msg->usage->{output_tokens}, 4, 'usage');
    ok(!$msg->has_error, 'null error is absent');
    my $blocks = $msg->content_blocks;
    is(scalar @$blocks, 3, 'three blocks');
    isa_ok($blocks->[0], 'Claude::Agent::Content::Text');
    is($blocks->[0]->raw->{cache_control}{type}, 'ephemeral', 'extra block key in raw');
    isa_ok($blocks->[1], 'Claude::Agent::Content::ToolUse');
    is($blocks->[1]->raw->{extra}, 1, 'extra tool_use key in raw');
    is(ref $blocks->[2], 'HASH', 'unknown block type stays a hashref');
    is($msg->text, 'Hi', 'text');
    is(scalar @{$msg->tool_uses}, 1, 'one tool use');
};

subtest 'content edge cases' => sub {
    my $tr = Claude::Agent::Content->from_json({
        type => 'tool_result', tool_use_id => 't1', content => [{ type => 'text', text => 'out' }],
        is_error => JSON::PP::false,
    });
    ok(!$tr->is_error, 'JSON false is_error');
    is($tr->text, 'out', 'text from blocks');
    my $plain = Claude::Agent::Content::Text->new(text => 'x');
    ok(!$plain->has_raw, 'a hand-built block has no raw');
    eval { $plain->type('y') };
    like($@, qr/readonly/, 'type is read only');
    eval { Claude::Agent::Content::Text->new(text => undef) };
    like($@, qr/Type constraint/, 'undef text is rejected');
};

done_testing();

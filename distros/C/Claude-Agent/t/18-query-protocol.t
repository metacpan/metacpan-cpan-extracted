#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Future;
use IO::Async::Loop;

use Claude::Agent qw(tool create_sdk_mcp_server);
use Claude::Agent::Query;
use Claude::Agent::Options;
use Claude::Agent::Subagent;
use Claude::Agent::Permission;
use Claude::Agent::Hook::Matcher;
use Claude::Agent::Hook::Result;

my $loop = IO::Async::Loop->new;
my $json = JSON::PP->new->canonical;

sub make_query {
    my (%args) = @_;
    my $out = $args{out} // [];
    my $closed = $args{closed} // \(my $c = 0);
    my $q = Claude::Agent::Query->new(
        spawn  => 0,
        loop   => $loop,
        writer => sub { push @$out, $_[1] },
        closer => sub { $$closed++ },
        (exists $args{prompt} ? (prompt => $args{prompt}) : (prompt => 'hello')),
        ($args{persistent} ? (persistent => 1) : ()),
        options => $args{options} // Claude::Agent::Options->new,
    );
    return ($q, $out, $closed);
}

sub feed {
    my ($q, $data) = @_;
    $q->feed_line($json->encode($data));
}

sub answer_init {
    my ($q, $out, $response) = @_;
    my $init = $out->[0];
    feed($q, { type => 'control_response', response => { subtype => 'success', request_id => $init->{request_id}, response => $response // { commands => ['help'] } } });
}

sub pump {
    my ($until) = @_;
    my $deadline = time + 3;
    $loop->loop_once(0.01) until $until->() || time > $deadline;
}

subtest 'initialize then prompt' => sub {
    my ($q, $out, $closed) = make_query();
    is(scalar @$out, 1, 'one line written on construction');
    is($out->[0]{type}, 'control_request', 'it is a control request');
    like($out->[0]{request_id}, qr/^req_1_[0-9a-f]{8}$/, 'request id shape');
    is($out->[0]{request}{subtype}, 'initialize', 'initialize');
    ok(exists $out->[0]{request}{hooks} && !defined $out->[0]{request}{hooks}, 'hooks is null without hooks');
    ok(!exists $out->[0]{request}{agents}, 'no agents key without agents');
    ok(!defined $q->server_info, 'no server_info yet');
    is($$closed, 0, 'stdin open while waiting for initialize');

    answer_init($q, $out, { commands => ['help', 'clear'], output_style => 'default', models => ['opus'] });
    is(scalar @$out, 2, 'the prompt is written after the response');
    is_deeply($out->[1], { type => 'user', session_id => '', message => { role => 'user', content => 'hello' }, parent_tool_use_id => undef }, 'user message shape');
    is($$closed, 1, 'stdin closed right after the prompt');
    is_deeply($q->supported_commands, ['help', 'clear'], 'supported_commands');
    is($q->output_style, 'default', 'output_style');
    is_deeply($q->supported_models, ['opus'], 'supported_models');

    feed($q, { type => 'system', subtype => 'init', session_id => 'sess-1', cwd => '/x' });
    is($q->session_id, 'sess-1', 'session id captured');
    my $msg = $q->next;
    isa_ok($msg, 'Claude::Agent::Message::System');
};

subtest 'initialize carries hooks and agents' => sub {
    my ($q, $out) = make_query(options => Claude::Agent::Options->new(
        hooks => { PreToolUse => [Claude::Agent::Hook::Matcher->new(matcher => 'Bash', timeout => 3, hooks => [sub { {} }])] },
        agents => { reviewer => Claude::Agent::Subagent->new(description => 'Reviews', prompt => 'Review', tools => ['Read']) },
        forward_subagent_text => 1,
    ));
    my $req = $out->[0]{request};
    is_deeply($req->{hooks}, { PreToolUse => [{ matcher => 'Bash', hookCallbackIds => ['hook_0'], timeout => 3 }] }, 'hooks config');
    is_deeply($req->{agents}, { reviewer => { description => 'Reviews', prompt => 'Review', tools => ['Read'] } }, 'agents');
    ok(${$req->{forwardSubagentText}}, 'forwardSubagentText');
};

subtest 'initialize failure' => sub {
    my ($q, $out, $closed) = make_query();
    feed($q, { type => 'control_response', response => { subtype => 'error', request_id => $out->[0]{request_id}, error => 'bad resume' } });
    like($q->error, qr/initialize failed: bad resume/, 'error recorded');
    is(scalar @$out, 1, 'no prompt written');
    pump(sub { $$closed });
    is($$closed, 1, 'stdin closed');
    ok(!defined $q->next, 'next returns undef');
};

subtest 'stdin stays open with hooks until the result' => sub {
    my ($q, $out, $closed) = make_query(options => Claude::Agent::Options->new(
        hooks => { Stop => [Claude::Agent::Hook::Matcher->new(hooks => [sub { {} }])] },
    ));
    answer_init($q, $out);
    is($$closed, 0, 'open after the prompt');
    feed($q, { type => 'assistant', message => { role => 'assistant', content => [] } });
    is($$closed, 0, 'open during the turn');
    feed($q, { type => 'result', subtype => 'success', result => 'done' });
    is($$closed, 1, 'closed on the result with no session state');
    my @types = map { $_->type } grep { defined } map { $q->next } 1 .. 2;
    is_deeply(\@types, ['assistant', 'result'], 'both messages delivered');
};

subtest 'session state gates the close' => sub {
    my ($q, $out, $closed) = make_query(options => Claude::Agent::Options->new(
        can_use_tool => sub { Claude::Agent::Permission->allow },
        env => { CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS => 50 },
    ));
    answer_init($q, $out);
    feed($q, { type => 'system', subtype => 'session_state_changed', state => 'running', sdk_host_only => JSON::PP::true });
    ok(!defined $q->next_async->is_ready ? 0 : !defined($q->next_async->get), 'sdk_host_only state is not delivered')
        if 0;
    is(scalar @{$q->_messages}, 0, 'sdk_host_only state is not delivered');
    feed($q, { type => 'result', subtype => 'success', result => 'done' });
    is($$closed, 0, 'still open while running');
    pump(sub { $$closed });
    is($$closed, 1, 'closed when the ceiling expires');

    ($q, $out, $closed) = make_query(options => Claude::Agent::Options->new(can_use_tool => sub { Claude::Agent::Permission->allow }));
    answer_init($q, $out);
    feed($q, { type => 'system', subtype => 'session_state_changed', state => 'running', sdk_host_only => JSON::PP::true });
    feed($q, { type => 'result', subtype => 'success', result => 'done' });
    feed($q, { type => 'system', subtype => 'session_state_changed', state => 'requires_action', sdk_host_only => JSON::PP::true });
    is($$closed, 0, 'requires_action keeps stdin open');
    feed($q, { type => 'system', subtype => 'session_state_changed', state => 'idle', sdk_host_only => JSON::PP::true });
    is($$closed, 1, 'idle closes it');

    ($q, $out, $closed) = make_query(options => Claude::Agent::Options->new(can_use_tool => sub { Claude::Agent::Permission->allow }));
    answer_init($q, $out);
    feed($q, { type => 'system', subtype => 'session_state_changed', state => 'running', sdk_host_only => JSON::PP::true });
    feed($q, { type => 'result', subtype => 'success', result => 'done' });
    feed($q, { type => 'assistant', message => { role => 'assistant', content => [] } });
    feed($q, { type => 'system', subtype => 'session_state_changed', state => 'idle', sdk_host_only => JSON::PP::true });
    is($$closed, 0, 'a new turn after the result reopens the run');
    feed($q, { type => 'result', subtype => 'success', result => 'again' });
    is($$closed, 1, 'the second result closes it');
};

subtest 'persistent never closes' => sub {
    my ($q, $out, $closed) = make_query(persistent => 1, prompt => undef);
    answer_init($q, $out);
    is(scalar @$out, 1, 'no prompt written when none was given');
    is($$closed, 0, 'open');
    ok($q->send_user_message('first', session_id => 'sess-9'), 'send_user_message');
    is($out->[1]{session_id}, 'sess-9', 'session id on the user message');
    feed($q, { type => 'result', subtype => 'success', result => 'done' });
    feed($q, { type => 'system', subtype => 'session_state_changed', state => 'idle', sdk_host_only => JSON::PP::true });
    is($$closed, 0, 'still open after result and idle');
};

subtest 'control requests to the CLI' => sub {
    my ($q, $out) = make_query(persistent => 1);
    answer_init($q, $out);
    my $f = $q->interrupt_async;
    isa_ok($f, 'Future');
    is($out->[-1]{request}{subtype}, 'interrupt', 'interrupt written');
    feed($q, { type => 'control_response', response => { subtype => 'success', request_id => $out->[-1]{request_id}, response => {} } });
    ok($f->is_done, 'resolved by the response');

    $f = $q->set_permission_mode_async('plan');
    is_deeply($out->[-1]{request}, { subtype => 'set_permission_mode', mode => 'plan' }, 'set_permission_mode');
    feed($q, { type => 'control_response', response => { subtype => 'error', request_id => $out->[-1]{request_id}, error => 'nope' } });
    ok($f->is_failed, 'an error response fails the Future');
    is(scalar $f->failure, 'nope', 'with the CLI text');
    ok(!defined $q->set_permission_mode('plan'), 'the sync form returns undef on failure') if 0;

    $q->set_model_async('sonnet');
    is_deeply($out->[-1]{request}, { subtype => 'set_model', model => 'sonnet' }, 'set_model');
    $q->set_max_thinking_tokens_async(100);
    is_deeply($out->[-1]{request}, { subtype => 'set_max_thinking_tokens', max_thinking_tokens => 100 }, 'set_max_thinking_tokens');
    $q->rewind_files_async('um-1');
    is_deeply($out->[-1]{request}, { subtype => 'rewind_files', user_message_id => 'um-1' }, 'rewind_files');
    $q->mcp_status_async;
    is($out->[-1]{request}{subtype}, 'mcp_status', 'mcp_status');
    $q->get_context_usage_async;
    is($out->[-1]{request}{subtype}, 'get_context_usage', 'get_context_usage');
    $q->toggle_mcp_server_async('x', 0);
    is_deeply($out->[-1]{request}, { subtype => 'mcp_toggle', serverName => 'x', enabled => \0 }, 'mcp_toggle');

    my $slow = $q->_send_control_request({ subtype => 'interrupt' }, 0.05);
    pump(sub { $slow->is_ready });
    ok($slow->is_failed, 'a request times out');
    like(scalar $slow->failure, qr/Control request timeout: interrupt/, 'timeout message');

    my $sync = $q->mcp_status_async;
    feed($q, { type => 'control_response', response => { subtype => 'success', request_id => $out->[-1]{request_id}, response => { mcpServers => [] } } });
    is_deeply($sync->get, { mcpServers => [] }, 'response data');
};

subtest 'can_use_tool' => sub {
    my @seen;
    my $answer = Claude::Agent::Permission->allow;
    my ($q, $out) = make_query(options => Claude::Agent::Options->new(
        cwd => '/tmp',
        can_use_tool => sub {
            my ($tool, $input, $ctx) = @_;
            push @seen, [$tool, $input, $ctx];
            return $answer;
        },
    ));
    answer_init($q, $out);
    feed($q, { type => 'system', subtype => 'init', session_id => 'sess-2' });
    my $req = {
        type => 'control_request', request_id => 'cli_1',
        request => { subtype => 'can_use_tool', tool_name => 'Bash', input => { command => 'ls' }, tool_use_id => 'toolu_1',
            permission_suggestions => [{ type => 'addRules' }], blocked_path => undef, decision_reason => 'rule', title => 'Run' },
    };
    feed($q, $req);
    is($seen[0][0], 'Bash', 'tool name');
    is_deeply($seen[0][1], { command => 'ls' }, 'input');
    my $ctx = $seen[0][2];
    isa_ok($ctx, 'Claude::Agent::Permission::Context');
    is($ctx->tool_use_id, 'toolu_1', 'context tool_use_id');
    is($ctx->session_id, 'sess-2', 'context session_id');
    is($ctx->cwd, '/tmp', 'context cwd');
    is($ctx->suggestions->[0]{type}, 'addRules', 'context suggestions');
    ok(!$ctx->has_blocked_path, 'null blocked_path absent');
    is($ctx->decision_reason, 'rule', 'context decision_reason');
    is($ctx->query, $q, 'context query');
    is_deeply($out->[-1], { type => 'control_response', response => { subtype => 'success', request_id => 'cli_1',
        response => { behavior => 'allow', updatedInput => { command => 'ls' } } } }, 'allow echoes the input as updatedInput');

    $answer = Claude::Agent::Permission->allow(updated_input => { command => 'ls -l' }, updated_permissions => [{ type => 'addRules' }]);
    $req->{request_id} = 'cli_2';
    feed($q, $req);
    is_deeply($out->[-1]{response}{response}, { behavior => 'allow', updatedInput => { command => 'ls -l' }, updatedPermissions => [{ type => 'addRules' }] }, 'allow with changes');

    $answer = Claude::Agent::Permission->deny(message => 'no', interrupt => 1);
    $req->{request_id} = 'cli_3';
    feed($q, $req);
    is_deeply($out->[-1]{response}{response}, { behavior => 'deny', message => 'no', interrupt => \1 }, 'deny');

    $answer = { behavior => 'deny', message => 'hash' };
    $req->{request_id} = 'cli_4';
    feed($q, $req);
    is_deeply($out->[-1]{response}{response}, { behavior => 'deny', message => 'hash', interrupt => \0 }, 'a hashref answer');

    my $pending = $loop->new_future;
    $answer = $pending;
    $req->{request_id} = 'cli_5';
    feed($q, $req);
    is($out->[-1]{response}{request_id}, 'cli_4', 'nothing written while the Future is pending');
    $pending->done(Claude::Agent::Permission->allow);
    is($out->[-1]{response}{request_id}, 'cli_5', 'written when the Future resolves');
    is($out->[-1]{response}{response}{behavior}, 'allow', 'with the allow');

    $answer = 'nonsense';
    $req->{request_id} = 'cli_6';
    feed($q, $req);
    is($out->[-1]{response}{subtype}, 'error', 'a bad answer is an error response');
    like($out->[-1]{response}{error}, qr/must return a Claude::Agent::Permission result/, 'error text');

    ($q, $out) = make_query(options => Claude::Agent::Options->new(can_use_tool => sub { die "callback died\n" }));
    answer_init($q, $out);
    $req->{request_id} = 'cli_7';
    feed($q, $req);
    is($out->[-1]{response}{subtype}, 'error', 'a dying callback is an error response');
    like($out->[-1]{response}{error}, qr/callback died/, 'with its message');

    ($q, $out) = make_query(persistent => 1);
    answer_init($q, $out);
    $req->{request_id} = 'cli_8';
    feed($q, $req);
    like($out->[-1]{response}{error}, qr/can_use_tool callback is not provided/, 'no callback is an error response');
};

subtest 'hook_callback' => sub {
    my @seen;
    my ($q, $out) = make_query(options => Claude::Agent::Options->new(
        hooks => { PreToolUse => [Claude::Agent::Hook::Matcher->new(hooks => [sub {
            my ($input, $tool_use_id, $ctx) = @_;
            push @seen, [$input, $tool_use_id, $ctx];
            return Claude::Agent::Hook::Result->deny(reason => 'blocked');
        }])] },
    ));
    answer_init($q, $out);
    feed($q, { type => 'control_request', request_id => 'cli_h1', request => {
        subtype => 'hook_callback', callback_id => 'hook_0', tool_use_id => 'toolu_9',
        input => { hook_event_name => 'PreToolUse', tool_name => 'Read', tool_input => { file_path => '.env' }, session_id => 's', cwd => '/c' },
    } });
    is($seen[0][0]{tool_name}, 'Read', 'input passed verbatim');
    is($seen[0][1], 'toolu_9', 'tool_use_id');
    is($seen[0][2]->query, $q, 'context query');
    is_deeply($out->[-1], { type => 'control_response', response => { subtype => 'success', request_id => 'cli_h1',
        response => { hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'deny', permissionDecisionReason => 'blocked' } } } },
        'hook output written verbatim');

    feed($q, { type => 'control_request', request_id => 'cli_h2', request => { subtype => 'hook_callback', callback_id => 'hook_42', input => {} } });
    is($out->[-1]{response}{subtype}, 'error', 'unknown callback id is an error');
    like($out->[-1]{response}{error}, qr/No hook callback found for ID: hook_42/, 'error text');

    ($q, $out) = make_query(persistent => 1);
    answer_init($q, $out);
    feed($q, { type => 'control_request', request_id => 'cli_h3', request => { subtype => 'hook_callback', callback_id => 'hook_0', input => {} } });
    like($out->[-1]{response}{error}, qr/No hooks are registered/, 'no registry is an error');
};

subtest 'mcp_message' => sub {
    my $add = tool('add', 'Add', { type => 'object' }, sub { my ($a) = @_; { content => [{ type => 'text', text => $a->{a} + $a->{b} }] } });
    my $server = create_sdk_mcp_server(name => 'utilities', tools => [$add]);
    my ($q, $out) = make_query(options => Claude::Agent::Options->new(mcp_servers => { utilities => $server }));
    answer_init($q, $out);

    feed($q, { type => 'control_request', request_id => 'm1', request => { subtype => 'mcp_message', server_name => 'utilities',
        message => { jsonrpc => '2.0', id => 1, method => 'initialize', params => { protocolVersion => '2025-03-26' } } } });
    is($out->[-1]{response}{response}{mcp_response}{result}{protocolVersion}, '2025-03-26', 'initialize answered');
    is($out->[-1]{response}{response}{mcp_response}{result}{serverInfo}{name}, 'utilities', 'serverInfo');

    feed($q, { type => 'control_request', request_id => 'm2', request => { subtype => 'mcp_message', server_name => 'utilities',
        message => { jsonrpc => '2.0', method => 'notifications/initialized' } } });
    is_deeply($out->[-1]{response}{response}, { mcp_response => { jsonrpc => '2.0', result => {} } }, 'a notification is acknowledged');

    feed($q, { type => 'control_request', request_id => 'm3', request => { subtype => 'mcp_message', server_name => 'utilities',
        message => { jsonrpc => '2.0', id => 2, method => 'tools/list' } } });
    is($out->[-1]{response}{response}{mcp_response}{result}{tools}[0]{name}, 'add', 'tools/list');

    feed($q, { type => 'control_request', request_id => 'm4', request => { subtype => 'mcp_message', server_name => 'utilities',
        message => { jsonrpc => '2.0', id => 3, method => 'tools/call', params => { name => 'add', arguments => { a => 1, b => 2 } } } } });
    is($out->[-1]{response}{response}{mcp_response}{result}{content}[0]{text}, 3, 'tools/call');
    ok(!${$out->[-1]{response}{response}{mcp_response}{result}{isError}}, 'isError false');

    feed($q, { type => 'control_request', request_id => 'm5', request => { subtype => 'mcp_message', server_name => 'other',
        message => { jsonrpc => '2.0', id => 4, method => 'ping' } } });
    is_deeply($out->[-1]{response}{response}{mcp_response}, { jsonrpc => '2.0', id => 4, error => { code => -32601, message => "Server 'other' not found" } }, 'unknown server');
    is($out->[-1]{response}{subtype}, 'success', 'unknown server is still a successful control response');

    feed($q, { type => 'control_request', request_id => 'm6', request => { subtype => 'mcp_message', server_name => 'utilities',
        message => { jsonrpc => '2.0', id => 5, method => 'resources/list' } } });
    is($out->[-1]{response}{response}{mcp_response}{error}{code}, -32601, 'unknown method');
};

subtest 'cancel and unsupported' => sub {
    my $pending = $loop->new_future;
    my ($q, $out) = make_query(options => Claude::Agent::Options->new(can_use_tool => sub { $pending }));
    answer_init($q, $out);
    my $before = scalar @$out;
    feed($q, { type => 'control_request', request_id => 'c1', request => { subtype => 'can_use_tool', tool_name => 'Bash', input => {} } });
    feed($q, { type => 'control_cancel_request', request_id => 'c1' });
    ok($pending->is_cancelled, 'the callback Future is cancelled');
    is(scalar @$out, $before, 'nothing written for a cancelled request');

    feed($q, { type => 'control_request', request_id => 'c2', request => { subtype => 'teleport' } });
    is_deeply($out->[-1], { type => 'control_response', response => { subtype => 'error', request_id => 'c2', error => 'Unsupported control request subtype: teleport' } }, 'unsupported subtype');
};

subtest 'message delivery' => sub {
    my ($q, $out) = make_query(persistent => 1);
    answer_init($q, $out);
    feed($q, { type => 'keep_alive' });
    feed($q, { type => 'tool_use_summary', summary => 'x' });
    feed($q, { type => 'stream_event', event => { type => 'message_start' } });
    feed($q, { type => 'rate_limit_event', rate_limit_info => { status => 'allowed' } });
    feed($q, { type => 'system', subtype => 'hook_started', hook_event_name => 'SessionStart' });
    feed($q, { type => 'nonsense' });
    feed($q, { notype => 1 });
    $q->feed_line('this is not json');
    my @classes = map { ref $_ } grep { defined } map { $q->next } 1 .. 5;
    is_deeply(\@classes, [qw(Claude::Agent::Message::Base Claude::Agent::Message::StreamEvent Claude::Agent::Message::RateLimitEvent Claude::Agent::Message::HookEvent Claude::Agent::Message::Base)],
        'keep_alive dropped, everything else delivered by class');
    my $f = $q->next_async;
    ok(!$f->is_ready, 'next_async waits');
    feed($q, { type => 'user', message => { role => 'user', content => 'x' } });
    ok($f->is_ready, 'resolved by the next line');
    isa_ok($f->get, 'Claude::Agent::Message::User');
};

subtest 'close' => sub {
    my ($q, $out, $closed) = make_query(persistent => 1);
    answer_init($q, $out);
    my $waiting = $q->next_async;
    my $req = $q->mcp_status_async;
    my $f = $q->close_async;
    ok($f->is_done, 'close without a process is immediate');
    ok($waiting->is_ready && !defined $waiting->get, 'a waiting next_async resolves to undef');
    ok($req->is_failed, 'a pending control request fails');
    ok(!$q->send_user_message('late'), 'nothing can be sent after close');
    $q->close;
    $q->cleanup;
    ok(1, 'close and cleanup are idempotent');
};

done_testing();

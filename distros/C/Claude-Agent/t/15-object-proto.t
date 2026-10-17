#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype);
use Object::Proto ();

use Claude::Agent::Types;
use Claude::Agent::Options;
use Claude::Agent::Content;
use Claude::Agent::Message;
use Claude::Agent::Error;
use Claude::Agent::Permission;
use Claude::Agent::Hook;
use Claude::Agent::MCP;
use Claude::Agent::Subagent;
use Claude::Agent::Query;

subtest 'types are registered' => sub {
    ok(Object::Proto::has_type($_), "$_ is registered") for qw(StrList StrOrHashRef StrOrArrayRef PermissionMode Effort);
    eval { Claude::Agent::Options->new(permission_mode => 'bogus') };
    like($@, qr/Type constraint failed for 'permission_mode'/, 'PermissionMode rejects an unknown mode');
    eval { Claude::Agent::Options->new(allowed_tools => ['a', []]) };
    like($@, qr/expected StrList/, 'StrList rejects a nested ref');
    eval { Claude::Agent::Options->new(allowed_tools => 'Read') };
    like($@, qr/expected StrList/, 'StrList rejects a string');
    eval { Claude::Agent::Options->new(system_prompt => ['x']) };
    like($@, qr/expected StrOrHashRef/, 'StrOrHashRef rejects an array');
    eval { Claude::Agent::Content::ToolResult->new(tool_use_id => 't', content => {}) };
    like($@, qr/expected StrOrArrayRef/, 'StrOrArrayRef rejects a hash');
};

subtest 'unknown constructor keys' => sub {
    my $o = Claude::Agent::Options->new(model => 'x', bogus => 1);
    is($o->model, 'x', 'known key kept');
    ok(!$o->can('bogus'), 'no accessor appears');
    $o = Claude::Agent::Options->new(bogus => 1, model => 'y');
    is($o->model, 'y', 'an unknown first key does not shift the values');
    eval { Claude::Agent::Options->create(bogus => 1) };
    like($@, qr/Unknown option\(s\) for Claude::Agent::Options: bogus/, 'create dies');
    my %known = Claude::Agent::Types::known_args('Claude::Agent::Options', { model => 'z', nope => 1, cwd => undef });
    is_deeply(\%known, { model => 'z' }, 'known_args keeps known, defined keys only');
};

subtest 'predicates are defined-based' => sub {
    my $o = Claude::Agent::Options->new(output_format => undef);
    ok(!$o->has_output_format, 'an explicit undef counts as absent');
    ok(!Claude::Agent::Permission::Result::Allow->new(updated_input => undef)->has_updated_input, 'same on Allow');
    is_deeply(Claude::Agent::Permission::Result::Allow->new(updated_input => undef)->to_hash, { behavior => 'allow' }, 'to_hash omits it');
    ok(Claude::Agent::Options->new(max_turns => 0)->has_max_turns, 'zero is present');
};

subtest 'undef and typed slots' => sub {
    my $deny = Claude::Agent::Permission->deny;
    ok(!$deny->has_message, 'deny without a message');
    is($deny->behavior, 'deny', 'behavior forced');
    is_deeply($deny->to_hash, { behavior => 'deny', interrupt => \0 }, 'to_hash');
    eval { Claude::Agent::Content::Text->new(text => undef) };
    like($@, qr/Type constraint failed for 'text'/, 'a typed slot rejects undef');
    my $ctx = Claude::Agent::Hook::Context->new(session_id => undef, cwd => undef);
    ok(!$ctx->has_session_id && !$ctx->has_cwd, 'untyped slots accept undef as absent');
    my $text = Claude::Agent::Content::Text->new(text => 'x');
    eval { $text->text(undef) };
    like($@, qr/Cannot set required slot|Type constraint failed/, 'the setter rejects undef too');
};

subtest 'errors' => sub {
    my $err = Claude::Agent::Error::ProcessError->new(message => 'm', exit_code => 3);
    is("$err", 'ProcessError: m', 'overload through the subclass');
    is($err->exit_code, 3, 'subclass slot');
    eval { Claude::Agent::Error::TimeoutError->throw(message => 'slow', timeout_ms => 5) };
    isa_ok($@, 'Claude::Agent::Error::TimeoutError');
    isa_ok($@, 'Claude::Agent::Error');
    is($@->timeout_ms, 5, 'thrown with its slot');
    eval { Claude::Agent::Error->new };
    like($@, qr/Required slot 'message'/, 'message is required');
};

subtest 'defaults are fresh per object' => sub {
    my ($a, $b) = map { Claude::Agent::Hook::Matcher->new } 1 .. 2;
    isnt($a->hooks, $b->hooks, 'arrayref default is fresh');
    push @{$a->hooks}, sub { };
    is(scalar @{$b->hooks}, 0, 'and independent');
    my ($c, $d) = map { Claude::Agent::MCP::StdioServer->new(command => '/bin/sh') } 1 .. 2;
    isnt($c->env, $d->env, 'hashref default is fresh');
    is(Claude::Agent::MCP::Server->new(name => 'n')->version, '1.0.0', 'a dotted version default survives');
};

subtest 'readonly type slots' => sub {
    for my $pair (['Text', { text => 'x' }, 'text'], ['Thinking', { thinking => 'x' }, 'thinking'],
                  ['ToolUse', { id => 'i', name => 'n', input => {} }, 'tool_use'],
                  ['ToolResult', { tool_use_id => 't', content => 'c' }, 'tool_result']) {
        my ($class, $args, $type) = @$pair;
        my $obj = "Claude::Agent::Content::$class"->new(%$args);
        is($obj->type, $type, "$class type");
        eval { $obj->type('other') };
        like($@, qr/readonly/, "$class type is read only");
    }
    is(Claude::Agent::Content->from_json({ type => 'text', text => 'x' })->type, 'text', 'from_json sets type');
};

subtest 'to_hash snapshots' => sub {
    is_deeply(
        Claude::Agent::Options->new(allowed_tools => ['Read'], permission_mode => 'plan', max_turns => 5)->to_hash,
        { allowedTools => ['Read'], permissionMode => 'plan', maxTurns => 5, queryTimeout => 600 },
        'options to_hash',
    );
    is_deeply(
        Claude::Agent::Subagent->new(description => 'd', prompt => 'p', model => 'opus')->to_hash,
        { description => 'd', prompt => 'p', model => 'opus' },
        'subagent to_hash',
    );
    is_deeply(
        Claude::Agent::MCP::SSEServer->new(url => 'https://x', headers => { A => 1 })->to_hash,
        { type => 'sse', url => 'https://x', headers => { A => 1 } },
        'sse to_hash',
    );
    is_deeply(
        Claude::Agent::Permission->deny(message => 'no', interrupt => 1)->to_hash,
        { behavior => 'deny', message => 'no', interrupt => \1 },
        'deny to_hash',
    );
};

subtest 'objects are arrays' => sub {
    my $o = Claude::Agent::Options->new;
    is(reftype($o), 'ARRAY', 'Options is an array');
    eval { my $x = $o->{model} };
    like($@, qr/Not a HASH reference/, 'hash access dies');
    my %slots = map { $_ => 1 } Object::Proto::properties('Claude::Agent::Query');
    ok($slots{_pending_control} && $slots{_inflight_requests} && $slots{_sdk_bridges}, 'Query state lives in slots');
};

done_testing();

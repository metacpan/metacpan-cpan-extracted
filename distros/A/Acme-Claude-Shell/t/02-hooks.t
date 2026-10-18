#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use_ok('Acme::Claude::Shell::Hooks', 'safety_hooks');
use_ok('Acme::Claude::Shell::Session');
use_ok('Claude::Agent::Hook::Matcher');
use_ok('Claude::Agent::Hook::Registry');

my $loop = IO::Async::Loop->new;

sub make_session {
    return Acme::Claude::Shell::Session->new(loop => $loop, colorful => 0, @_);
}

my $session = make_session();
my $hooks = safety_hooks($session);
ok($hooks, 'safety_hooks returns hooks');
is(ref($hooks), 'HASH', 'safety_hooks returns hashref');

for my $hook_type (qw(PreToolUse PostToolUse PostToolUseFailure Stop Notification)) {
    ok(exists $hooks->{$hook_type}, "$hook_type hooks exist");
    ok(ref($hooks->{$hook_type}) eq 'ARRAY', "$hook_type is arrayref");
    ok(scalar(@{$hooks->{$hook_type}}) > 0, "$hook_type has matchers");
    for my $matcher (@{$hooks->{$hook_type}}) {
        isa_ok($matcher, 'Claude::Agent::Hook::Matcher', "$hook_type matcher");
    }
}

subtest 'PreToolUse matcher' => sub {
    my $matcher = $hooks->{PreToolUse}[0];
    ok($matcher->matches('mcp__shell-tools__execute_command'), 'Matches execute_command');
    ok($matcher->matches('mcp__shell-tools__read_file'), 'Matches read_file');
    ok($matcher->matches('mcp__shell-tools__list_directory'), 'Matches list_directory');
    ok(!$matcher->matches('some_other_tool'), 'Does not match other tools');
};

subtest 'PostToolUse matcher' => sub {
    my $matcher = $hooks->{PostToolUse}[0];
    ok($matcher->matches('mcp__shell-tools__execute_command'), 'Matches execute_command');
    ok(!$matcher->matches('mcp__shell-tools__read_file'), 'Does not match read_file');
    ok(!$matcher->matches('mcp__shell-tools__list_directory'), 'Does not match list_directory');
};

subtest 'PostToolUseFailure matcher' => sub {
    my $matcher = $hooks->{PostToolUseFailure}[0];
    ok($matcher->matches('mcp__shell-tools__execute_command'), 'Matches execute_command');
    ok($matcher->matches('mcp__shell-tools__read_file'), 'Matches read_file');
};

subtest 'Stop and Notification matchers match anything' => sub {
    ok($hooks->{Stop}[0]->matches('end_turn'), 'Stop matches end_turn');
    ok($hooks->{Notification}[0]->matches('any_notification'), 'Notification matches anything');
};

subtest 'Session statistics initialization' => sub {
    my $fresh = make_session();
    ok(!$fresh->_session_start, 'no start time before the hooks are built');
    safety_hooks($fresh);
    ok($fresh->_session_start, 'Session start time initialized');
    is($fresh->_tool_count, 0, 'Tool count starts at zero');
    is($fresh->_tool_errors, 0, 'Tool errors start at zero');
};

subtest 'hooks run through the registry' => sub {
    my $audit = make_session(audit_log => 1);
    my $registry = Claude::Agent::Hook::Registry->new(hooks => safety_hooks($audit), loop => $loop);
    my $config = $registry->to_initialize_config;
    is_deeply([sort keys %$config], [qw(Notification PostToolUse PostToolUseFailure PreToolUse Stop)], 'every event is registered');
    is($config->{PreToolUse}[0]{matcher}, 'mcp__shell-tools__.*', 'the PreToolUse pattern is sent to the CLI');

    my %id_for;
    for my $event (keys %$config) {
        $id_for{$event} = $config->{$event}[0]{hookCallbackIds}[0];
    }

    my $out = $registry->run($id_for{PreToolUse}, {
        hook_event_name => 'PreToolUse',
        tool_name       => 'mcp__shell-tools__read_file',
        tool_input      => { path => '/tmp/test.txt' },
    }, 'test-id-123')->get;
    is_deeply($out, {}, 'PreToolUse proceeds');
    is(scalar @{$audit->_audit_log}, 1, 'One audit entry');
    is($audit->_audit_log->[0]{tool}, 'read_file', 'audit entry has the short tool name');
    is($audit->_audit_log->[0]{tool_use_id}, 'test-id-123', 'audit entry has the tool use id');

    $out = $registry->run($id_for{PostToolUse}, {
        hook_event_name => 'PostToolUse', tool_name => 'mcp__shell-tools__execute_command', tool_input => { command => 'ls' },
    }, 'test-id-124')->get;
    is_deeply($out, {}, 'PostToolUse proceeds');
    is($audit->_tool_count, 1, 'tool count incremented');

    my $printed = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$printed or die $!;
        $out = $registry->run($id_for{PostToolUseFailure}, {
            hook_event_name => 'PostToolUseFailure', tool_name => 'mcp__shell-tools__execute_command', error => 'boom',
        }, 'test-id-125')->get;
        $registry->run($id_for{Notification}, {
            hook_event_name => 'Notification', notification_type => 'permission_prompt', message => 'Claude needs you',
        }, undef)->get;
        $registry->run($id_for{Stop}, { hook_event_name => 'Stop', stop_hook_active => 0 }, undef)->get;
    }
    is_deeply($out, {}, 'PostToolUseFailure proceeds');
    is($audit->_tool_errors, 1, 'tool error counted');
    like($printed, qr/Tool 'execute_command' failed: boom/, 'failure reported');
    like($printed, qr/Tools used: 1/, 'statistics printed on Stop');
    unlike($printed, qr/Notification/, 'notifications are quiet unless verbose');

    my $chatty = make_session(verbose => 1);
    my $chatty_registry = Claude::Agent::Hook::Registry->new(hooks => safety_hooks($chatty), loop => $loop);
    my $chatty_config = $chatty_registry->to_initialize_config;
    $printed = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$printed or die $!;
        $chatty_registry->run($chatty_config->{Notification}[0]{hookCallbackIds}[0], {
            hook_event_name => 'Notification', notification_type => 'idle', message => 'Waiting',
        }, undef)->get;
        $chatty_registry->run($chatty_config->{PreToolUse}[0]{hookCallbackIds}[0], {
            hook_event_name => 'PreToolUse', tool_name => 'mcp__shell-tools__search_files', tool_input => {},
        }, 'x')->get;
    }
    like($printed, qr/\[Notification\] idle - Waiting/, 'verbose notification');
    like($printed, qr/\[Tool\] search_files/, 'verbose tool log');
};

done_testing();

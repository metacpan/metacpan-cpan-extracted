#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;

# Test the Hooks module functionality

use_ok('Acme::Claude::Shell::Hooks', 'safety_hooks');
use_ok('Claude::Agent::Hook::Matcher');
use_ok('Claude::Agent::Hook::Result');

# Create a mock session object for testing
package MockSession;
sub new {
    my ($class, %args) = @_;
    return bless {
        working_dir => $args{working_dir} // '.',
        colorful    => $args{colorful} // 0,
        safe_mode   => $args{safe_mode} // 1,
        verbose     => $args{verbose} // 0,
        audit_log   => $args{audit_log} // 0,
        _history    => [],
        _spinner    => undef,
    }, $class;
}
sub working_dir { $_[0]->{working_dir} }
sub colorful { $_[0]->{colorful} }
sub safe_mode { $_[0]->{safe_mode} }
sub _history { $_[0]->{_history} }
sub _spinner {
    my $self = shift;
    if (@_) { $self->{_spinner} = shift }
    return $self->{_spinner};
}
sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) || ($method eq '_spinner' ? 1 : 0);
}

package main;

# Create mock session
my $session = MockSession->new(
    colorful  => 0,
    safe_mode => 1,
    verbose   => 0,
);

# Get hooks
my $hooks = safety_hooks($session);
ok($hooks, 'safety_hooks returns hooks');
is(ref($hooks), 'HASH', 'safety_hooks returns hashref');

# Check expected hook types exist
ok(exists $hooks->{PreToolUse}, 'PreToolUse hooks exist');
ok(exists $hooks->{PostToolUse}, 'PostToolUse hooks exist');
ok(exists $hooks->{PostToolUseFailure}, 'PostToolUseFailure hooks exist');
ok(exists $hooks->{Stop}, 'Stop hooks exist');
ok(exists $hooks->{Notification}, 'Notification hooks exist');

# Check each hook type has matchers
for my $hook_type (qw(PreToolUse PostToolUse PostToolUseFailure Stop Notification)) {
    ok(ref($hooks->{$hook_type}) eq 'ARRAY', "$hook_type is arrayref");
    ok(scalar(@{$hooks->{$hook_type}}) > 0, "$hook_type has matchers");

    for my $matcher (@{$hooks->{$hook_type}}) {
        isa_ok($matcher, 'Claude::Agent::Hook::Matcher', "$hook_type matcher");
        ok($matcher->can('matches'), "Matcher has matches method");
        ok($matcher->can('run_hooks'), "Matcher has run_hooks method");
    }
}

# Test PreToolUse matcher pattern
subtest 'PreToolUse matcher' => sub {
    plan tests => 4;

    my $matcher = $hooks->{PreToolUse}[0];

    # Should match shell-tools tools
    ok($matcher->matches('mcp__shell-tools__execute_command'), 'Matches execute_command');
    ok($matcher->matches('mcp__shell-tools__read_file'), 'Matches read_file');
    ok($matcher->matches('mcp__shell-tools__list_directory'), 'Matches list_directory');

    # Should not match other tools
    ok(!$matcher->matches('some_other_tool'), 'Does not match other tools');
};

# Test PostToolUse matcher pattern (only execute_command)
subtest 'PostToolUse matcher' => sub {
    plan tests => 3;

    my $matcher = $hooks->{PostToolUse}[0];

    # Should match execute_command
    ok($matcher->matches('mcp__shell-tools__execute_command'), 'Matches execute_command');

    # Should not match other shell-tools
    ok(!$matcher->matches('mcp__shell-tools__read_file'), 'Does not match read_file');
    ok(!$matcher->matches('mcp__shell-tools__list_directory'), 'Does not match list_directory');
};

# Test PostToolUseFailure matcher pattern
subtest 'PostToolUseFailure matcher' => sub {
    plan tests => 2;

    my $matcher = $hooks->{PostToolUseFailure}[0];

    # Should match any shell-tools
    ok($matcher->matches('mcp__shell-tools__execute_command'), 'Matches execute_command');
    ok($matcher->matches('mcp__shell-tools__read_file'), 'Matches read_file');
};

# Test Stop matcher (matches everything)
subtest 'Stop matcher' => sub {
    plan tests => 2;

    my $matcher = $hooks->{Stop}[0];

    ok($matcher->matches('end_turn'), 'Matches end_turn');
    ok($matcher->matches('anything'), 'Matches anything');
};

# Test Notification matcher (matches everything)
subtest 'Notification matcher' => sub {
    plan tests => 2;

    my $matcher = $hooks->{Notification}[0];

    ok($matcher->matches('message'), 'Matches message');
    ok($matcher->matches('any_notification'), 'Matches any notification');
};

# Test session statistics are initialized
subtest 'Session statistics initialization' => sub {
    plan tests => 3;

    # Create fresh session
    my $fresh_session = MockSession->new(colorful => 0);
    my $fresh_hooks = safety_hooks($fresh_session);

    ok(exists $fresh_session->{_session_start}, 'Session start time initialized');
    ok(exists $fresh_session->{_tool_count}, 'Tool count initialized');
    ok(exists $fresh_session->{_tool_errors}, 'Tool errors initialized');
};

# Test audit log option
subtest 'Audit log option' => sub {
    plan tests => 2;

    my $audit_session = MockSession->new(
        colorful  => 0,
        audit_log => 1,
    );
    my $audit_hooks = safety_hooks($audit_session);

    # Run a PreToolUse hook
    my $matcher = $audit_hooks->{PreToolUse}[0];
    my $input = {
        tool_name  => 'mcp__shell-tools__read_file',
        tool_input => { path => '/tmp/test.txt' },
    };

    # Create mock context
    my $context = bless {}, 'Claude::Agent::Hook::Context';

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $future = $matcher->run_hooks($input, 'test-id-123', $context, $loop);
    my $results = $future->get;

    # Check audit log was populated
    ok(exists $audit_session->{_audit_log}, 'Audit log created');
    is(scalar(@{$audit_session->{_audit_log} // []}), 1, 'One audit entry');
};

# Test hook returns proper Result
subtest 'Hook returns proper Result' => sub {
    plan tests => 2;

    my $matcher = $hooks->{PreToolUse}[0];
    my $input = {
        tool_name  => 'mcp__shell-tools__execute_command',
        tool_input => { command => 'ls' },
    };

    my $context = bless {}, 'Claude::Agent::Hook::Context';

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $future = $matcher->run_hooks($input, 'test-id', $context, $loop);
    my $results = $future->get;

    ok(ref($results) eq 'ARRAY', 'Results is array');
    ok($results->[0]{decision} eq 'continue', 'Returns continue decision');
};

done_testing();

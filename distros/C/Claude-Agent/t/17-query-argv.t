#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use IO::Async::Loop;

use Claude::Agent qw(tool create_sdk_mcp_server);
use Claude::Agent::Query;
use Claude::Agent::Options;
use Claude::Agent::Subagent;
use Claude::Agent::MCP::StdioServer;
use Claude::Agent::MCP::HTTPServer;

my $loop = IO::Async::Loop->new;
my $json = JSON::PP->new->canonical;

sub argv {
    my (%options) = @_;
    my $q = Claude::Agent::Query->new(
        prompt  => 'hello',
        spawn   => 0,
        loop    => $loop,
        writer  => sub { },
        options => Claude::Agent::Options->new(%options),
    );
    return [ $q->_build_command('/fake/claude') ];
}

sub flag_value {
    my ($argv, $flag) = @_;
    for my $i (0 .. $#$argv) {
        return $argv->[$i + 1] if $argv->[$i] eq $flag;
    }
    return;
}

subtest 'base argv' => sub {
    my $argv = argv();
    is_deeply($argv, ['/fake/claude', '--output-format', 'stream-json', '--verbose', '--input-format', 'stream-json'],
        'no options gives the bare command');
    ok(!grep({ $_ eq '--print' } @$argv), 'no --print');
    ok(!grep({ $_ eq 'hello' } @$argv), 'the prompt is not on argv');
    is($argv->[-1], 'stream-json', '--input-format stream-json is last');
};

subtest 'tool and model flags' => sub {
    my $argv = argv(
        allowed_tools    => ['Read', 'Bash(git:*)'],
        disallowed_tools => ['Write'],
        tools            => ['Bash', 'Read'],
        model            => 'opus',
        fallback_model   => 'sonnet',
        betas            => ['a', 'b'],
        max_turns        => 5,
        max_budget_usd   => 1.5,
        effort           => 'max',
    );
    is(flag_value($argv, '--allowedTools'), 'Read,Bash(git:*)', 'allowedTools comma-joined');
    is(flag_value($argv, '--disallowedTools'), 'Write', 'disallowedTools');
    is(flag_value($argv, '--tools'), 'Bash,Read', 'tools');
    is(flag_value($argv, '--model'), 'opus', 'model');
    is(flag_value($argv, '--fallback-model'), 'sonnet', 'fallback model');
    is(flag_value($argv, '--betas'), 'a,b', 'betas');
    is(flag_value($argv, '--max-turns'), 5, 'max turns');
    is(flag_value($argv, '--max-budget-usd'), 1.5, 'max budget');
    is(flag_value($argv, '--effort'), 'max', 'effort');
    is(flag_value(argv(tools => []), '--tools'), '', 'empty tools is an empty string');
    is(flag_value(argv(tools => { type => 'preset' }), '--tools'), 'default', 'preset tools');
    ok(!grep({ $_ eq '--allowedTools' } @{ argv(allowed_tools => []) }), 'empty allowed_tools is omitted');
};

subtest 'permissions' => sub {
    my $argv = argv(permission_mode => 'default');
    is(flag_value($argv, '--permission-mode'), 'default', 'default mode is passed');
    $argv = argv(can_use_tool => sub { });
    is(flag_value($argv, '--permission-prompt-tool'), 'stdio', 'can_use_tool adds the stdio prompt tool');
    $argv = argv(permission_prompt_tool_name => 'mcp__x__ask');
    is(flag_value($argv, '--permission-prompt-tool'), 'mcp__x__ask', 'a named prompt tool');
    ok(!grep({ $_ eq '--permission-prompt-tool' } @{ argv() }), 'no prompt tool by default');
};

subtest 'sessions and settings' => sub {
    my $argv = argv(
        resume                => 'sess-1',
        fork_session          => 1,
        continue_conversation => 1,
        session_id            => '123e4567-e89b-12d3-a456-426614174000',
        setting_sources       => ['user', 'project'],
        add_dirs              => ['/a', '/b'],
        plugins               => [{ type => 'local', path => '/p1' }, { type => 'local', path => '/p2' }],
        strict_mcp_config     => 1,
        include_partial_messages => 1,
        include_hook_events   => 1,
    );
    ok(grep({ $_ eq '--resume=sess-1' } @$argv), 'resume in equals form');
    ok(grep({ $_ eq '--session-id=123e4567-e89b-12d3-a456-426614174000' } @$argv), 'session id in equals form');
    ok(grep({ $_ eq '--setting-sources=user,project' } @$argv), 'setting sources in equals form');
    ok(grep({ $_ eq '--fork-session' } @$argv), 'fork session');
    ok(grep({ $_ eq '--continue' } @$argv), 'continue');
    ok(grep({ $_ eq '--strict-mcp-config' } @$argv), 'strict mcp config');
    ok(grep({ $_ eq '--include-partial-messages' } @$argv), 'partial messages');
    ok(grep({ $_ eq '--include-hook-events' } @$argv), 'hook events');
    my @dirs = map { $argv->[$_ + 1] } grep { $argv->[$_] eq '--add-dir' } 0 .. $#$argv;
    is_deeply(\@dirs, ['/a', '/b'], 'one --add-dir per directory');
    my @plugins = map { $argv->[$_ + 1] } grep { $argv->[$_] eq '--plugin-dir' } 0 .. $#$argv;
    is_deeply(\@plugins, ['/p1', '/p2'], 'one --plugin-dir per plugin');

    is(flag_value(argv(settings => '/etc/claude.json'), '--settings'), '/etc/claude.json', 'settings path');
    is_deeply($json->decode(flag_value(argv(settings => { a => 1 }), '--settings')), { a => 1 }, 'settings hashref as JSON');
    is_deeply($json->decode(flag_value(argv(sandbox => { enabled => 1 }), '--settings')), { sandbox => { enabled => 1 } }, 'sandbox alone');
    is_deeply(
        $json->decode(flag_value(argv(settings => { a => 1 }, sandbox => { enabled => 1 }), '--settings')),
        { a => 1, sandbox => { enabled => 1 } }, 'sandbox merged into settings hashref');
    is_deeply(
        $json->decode(flag_value(argv(settings => '{"b":2}', sandbox => { enabled => 0 }), '--settings')),
        { b => 2, sandbox => { enabled => 0 } }, 'sandbox merged into a settings JSON string');
};

subtest 'system prompt' => sub {
    is(flag_value(argv(system_prompt => 'Be terse'), '--system-prompt'), 'Be terse', 'string prompt');
    my $preset = argv(system_prompt => { type => 'preset', preset => 'claude_code', append => 'And brief.' });
    is(flag_value($preset, '--append-system-prompt'), 'And brief.', 'preset with append');
    ok(!grep({ $_ eq '--system-prompt' } @$preset), 'preset does not replace the prompt');
    ok(!grep({ /system-prompt/ } @{ argv(system_prompt => { type => 'preset', preset => 'claude_code' }) }), 'preset without append adds nothing');
    is(flag_value(argv(system_prompt => { type => 'custom', prompt => 'Custom' }), '--system-prompt'), 'Custom', 'custom form');
    is(flag_value(argv(system_prompt => { type => 'file', path => '/p.txt' }), '--system-prompt-file'), '/p.txt', 'file form');
    is(flag_value(argv(system_prompt => { preset => 'x', append => 'Legacy' }), '--append-system-prompt'), 'Legacy', 'legacy preset hash is a preset');
    ok(!grep({ /system-prompt/ } @{ argv() }), 'unset leaves the CLI default');
    eval { argv(system_prompt => { type => 'bogus' }) };
    like($@, qr/type of preset, custom or file/, 'an unknown hashref type dies');
};

subtest 'thinking and structured output' => sub {
    my $argv = argv(thinking => { type => 'adaptive' });
    is(flag_value($argv, '--thinking'), 'adaptive', 'adaptive thinking');
    $argv = argv(thinking => { type => 'enabled', budget_tokens => 4096 });
    is(flag_value($argv, '--max-thinking-tokens'), 4096, 'enabled thinking budget');
    $argv = argv(thinking => { type => 'disabled' }, max_thinking_tokens => 10);
    is(flag_value($argv, '--thinking'), 'disabled', 'disabled thinking');
    ok(!grep({ $_ eq '--max-thinking-tokens' } @$argv), 'thinking wins over max_thinking_tokens');
    is(flag_value(argv(max_thinking_tokens => 2000), '--max-thinking-tokens'), 2000, 'max_thinking_tokens alone');
    my $schema = { type => 'object', properties => { name => { type => 'string' } } };
    is_deeply($json->decode(flag_value(argv(output_format => { type => 'json_schema', schema => $schema }), '--json-schema')),
        $schema, 'json schema');
};

subtest 'mcp config' => sub {
    my $sdk = create_sdk_mcp_server(name => 'utilities', tools => [tool('t', 'd', { type => 'object' }, sub { {} })]);
    my $stdio = Claude::Agent::MCP::StdioServer->new(command => '/usr/bin/npx', args => ['-y', 'pkg']);
    my $http = Claude::Agent::MCP::HTTPServer->new(url => 'https://x/mcp', headers => { A => 'b' });
    my $argv = argv(mcp_servers => { utilities => $sdk, fs => $stdio, remote => $http, raw => { type => 'sse', url => 'https://y' } });
    my $config = $json->decode(flag_value($argv, '--mcp-config'));
    is_deeply($config->{mcpServers}{utilities}, { type => 'sdk', name => 'utilities' }, 'sdk server has only type and name');
    is_deeply($config->{mcpServers}{fs}, { type => 'stdio', command => '/usr/bin/npx', args => ['-y', 'pkg'], env => {} }, 'stdio server');
    is_deeply($config->{mcpServers}{remote}, { type => 'http', url => 'https://x/mcp', headers => { A => 'b' } }, 'http server');
    is_deeply($config->{mcpServers}{raw}, { type => 'sse', url => 'https://y' }, 'a plain hashref passes through');
    ok(!grep({ $_ eq '--mcp-config' } @{ argv(mcp_servers => {}) }), 'empty mcp_servers adds nothing');
};

subtest 'agents are not on argv' => sub {
    my $argv = argv(agents => { r => Claude::Agent::Subagent->new(description => 'd', prompt => 'p') });
    ok(!grep({ $_ eq '--agents' } @$argv), 'no --agents flag');
};

subtest 'extra args' => sub {
    my $argv = argv(extra_args => { bare => undef, 'debug-file' => '/tmp/x.log', name => '-weird' });
    ok(grep({ $_ eq '--bare' } @$argv), 'undef value is a bare flag');
    is(flag_value($argv, '--debug-file'), '/tmp/x.log', 'value as a separate argument');
    ok(grep({ $_ eq '--name=-weird' } @$argv), 'a dash-leading value uses equals form');
};

subtest 'env' => sub {
    local $ENV{CLAUDECODE} = '1';
    local $ENV{KEEP_ME} = 'yes';
    delete local $ENV{CLAUDE_CODE_SDK_READS_SESSION_STATE};
    my $q = Claude::Agent::Query->new(prompt => 'x', spawn => 0, loop => $loop, writer => sub { },
        options => Claude::Agent::Options->new(env => { FOO => 'bar' }, cwd => '/tmp', enable_file_checkpointing => 1));
    my $env = $q->_build_env;
    ok(!exists $env->{CLAUDECODE}, 'CLAUDECODE is removed');
    is($env->{KEEP_ME}, 'yes', 'the environment is inherited');
    is($env->{CLAUDE_CODE_ENTRYPOINT}, 'sdk-perl', 'entrypoint');
    is($env->{CLAUDE_AGENT_SDK_VERSION}, $Claude::Agent::VERSION, 'sdk version');
    is($env->{CLAUDE_CODE_SDK_READS_SESSION_STATE}, '1', 'session state flag');
    is($env->{CLAUDE_CODE_ENABLE_SDK_FILE_CHECKPOINTING}, 'true', 'checkpointing');
    is($env->{FOO}, 'bar', 'env option applied');
    is($env->{PWD}, '/tmp', 'PWD follows cwd');

    $q = Claude::Agent::Query->new(prompt => 'x', spawn => 0, loop => $loop, writer => sub { },
        options => Claude::Agent::Options->new(env => { CLAUDE_CODE_ENTRYPOINT => 'mine', CLAUDE_CODE_SDK_READS_SESSION_STATE => '0' }));
    $env = $q->_build_env;
    is($env->{CLAUDE_CODE_ENTRYPOINT}, 'mine', 'env option overrides the entrypoint');
    is($env->{CLAUDE_CODE_SDK_READS_SESSION_STATE}, '0', 'an explicit session state flag is kept');
};

subtest 'prompt forms' => sub {
    my @out;
    my $q = Claude::Agent::Query->new(spawn => 0, loop => $loop, writer => sub { push @out, $_[1] });
    ok(!$q->has_prompt, 'a query may have no prompt');
    eval { Claude::Agent::Query->new(prompt => sub { }, spawn => 0, loop => $loop, writer => sub { }) };
    like($@, qr/prompt must be a string or an array/, 'a coderef prompt dies');
    $q = Claude::Agent::Query->new(prompt => [{ type => 'text', text => 'hi' }], spawn => 0, loop => $loop, writer => sub { });
    ok($q->has_prompt, 'an arrayref prompt is accepted');
};

subtest 'version probe' => sub {
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my %fake;
    for my $pair (['old', '2.0.5 (Claude Code)'], ['new', '9.9.9 (Claude Code)'], ['junk', 'no version here']) {
        my ($name, $text) = @$pair;
        my $path = "$dir/claude-$name";
        open my $fh, '>', $path or die $!;
        print $fh "#!/bin/sh\necho '$text'\n";
        close $fh;
        chmod 0755, $path;
        $fake{$name} = $path;
    }
    delete local $ENV{CLAUDE_AGENT_SDK_SKIP_VERSION_CHECK};
    my $q = Claude::Agent::Query->new(prompt => 'x', spawn => 0, loop => $loop, writer => sub { });
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $q->_check_claude_version($fake{old});
    is($q->cli_version($fake{old}), '2.0.5', 'the old version is recorded');
    is(scalar @warnings, 1, 'an old CLI warns once');
    like($warnings[0], qr/2\.0\.5 .* is older than 2\.1\.0/, 'the warning names both versions');
    $q->_check_claude_version($fake{old});
    is(scalar @warnings, 1, 'a second probe of the same path is cached');
    $q->_check_claude_version($fake{new});
    is($q->cli_version($fake{new}), '9.9.9', 'a new version is recorded');
    is(scalar @warnings, 1, 'a new CLI does not warn');
    $q->_check_claude_version($fake{junk});
    ok(!defined $q->cli_version($fake{junk}), 'unparseable output records nothing');
    is(scalar @warnings, 1, 'and does not warn');
    local $ENV{CLAUDE_AGENT_SDK_SKIP_VERSION_CHECK} = 1;
    $q->_check_claude_version("$dir/claude-missing");
    is(scalar @warnings, 1, 'the probe is skipped when asked');
};

done_testing();

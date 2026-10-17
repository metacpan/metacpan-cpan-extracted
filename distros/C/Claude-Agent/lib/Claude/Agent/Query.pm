package Claude::Agent::Query;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Scalar::Util qw(blessed);
use Time::HiRes ();
use Carp ();
use IO::Async::Loop;
use IO::Async::Process;
use Future;
use JSON::Lines;
use File::Which qw(which);
use File::Spec;
use Crypt::URandom ();
use Claude::Agent::Logger '$log';
use Claude::Agent::Types;
use Claude::Agent::Options;
use Claude::Agent::Message;
use Claude::Agent::Error;
use Claude::Agent::Permission;
use Claude::Agent::Hook::Registry;
use Claude::Agent::MCP::SDKBridge;
use Claude::Agent::DryRun qw(create_dry_run_hooks);

our $MINIMUM_CLAUDE_CODE_VERSION = '2.1.0';
our $ENTRYPOINT = 'sdk-perl';

sub DEMOLISH;

BEGIN {
    Object::Proto::define('Claude::Agent::Query',
        'prompt:predicate',
        'options:lazy:builder(_build_options)',
        'loop:predicate',
        'persistent:Bool:default(0)',
        'spawn:Bool:default(1)',
        'writer:predicate',
        'closer:predicate',
        '_loop',
        '_process',
        '_stdin',
        '_cli_path',
        '_messages:ArrayRef:default([])',
        '_pending_futures:ArrayRef:default([])',
        '_session_id',
        '_finished:Bool:default(0)',
        '_error',
        '_exit_future',
        '_hook_registry',
        '_sdk_bridges:HashRef:default({})',
        '_request_counter:Int:default(0)',
        '_pending_control:HashRef:default({})',
        '_inflight_requests:HashRef:default({})',
        '_init_result',
        '_result_received:Bool:default(0)',
        '_session_state',
        '_run_end_timer',
        '_turn_in_progress:Bool:default(0)',
        '_stdin_closed:Bool:default(0)',
        '_closed:Bool:default(0)',
        '_processing_message:Bool:default(0)',
        '_jsonl:lazy:builder(_build_jsonl)',
    );
}

my %CONSUMED = map { $_ => 1 } qw(keep_alive control_response control_request control_cancel_request);

sub _build_options { Claude::Agent::Options->new }

sub _build_jsonl {
    return JSON::Lines->new(
        utf8     => 1,
        error_cb => sub {
            my ($action, $error) = @_;
            $log->trace("JSON::Lines $action error: $error");
            return;
        },
    );
}

sub BUILD {
    my ($self) = @_;

    $self->_loop($self->has_loop ? $self->loop : IO::Async::Loop->new);
    $self->_exit_future($self->_loop->new_future);

    if ($self->has_prompt && ref $self->prompt && ref $self->prompt ne 'ARRAY') {
        Carp::croak("prompt must be a string or an array of content blocks");
    }

    my $opts = $self->options;

    my %hooks;
    if ($opts->has_hooks) {
        $hooks{$_} = [ @{ $opts->hooks->{$_} // [] } ] for keys %{$opts->hooks};
    }
    if ($opts->has_dry_run && $opts->dry_run) {
        my $dry = create_dry_run_hooks($opts->has_on_dry_run ? $opts->on_dry_run : undef);
        for my $event (keys %$dry) {
            unshift @{ $hooks{$event} //= [] }, @{$dry->{$event}};
        }
        $log->debug("Dry-run mode enabled");
    }
    if (%hooks) {
        $self->_hook_registry(Claude::Agent::Hook::Registry->new(
            hooks => \%hooks,
            loop  => $self->_loop,
            query => $self,
        ));
        $log->debug(sprintf("Hooks registered for: %s", join(', ', sort keys %hooks)));
    }

    if ($opts->has_mcp_servers) {
        for my $name (sort keys %{$opts->mcp_servers}) {
            my $server = $opts->mcp_servers->{$name};
            next unless blessed($server) && $server->can('type') && $server->type eq 'sdk';
            $self->_sdk_bridges->{$name} = Claude::Agent::MCP::SDKBridge->new(
                server => $server,
                loop   => $self->_loop,
            );
        }
    }

    $self->_start_process;
    return;
}

sub DEMOLISH {
    my ($self) = @_;
    return if $self->_finished || !$self->_process;
    eval { $self->_process->kill('TERM') };
    return;
}

sub _find_claude_cli {
    my ($self) = @_;

    return $self->options->cli_path if $self->options->has_cli_path;

    my $claude = which('claude');
    return $claude if $claude;

    my @paths = ('/usr/local/bin/claude', '/opt/homebrew/bin/claude');
    if ($ENV{HOME} && $ENV{HOME} =~ m{^/}) {
        require Cwd;
        my $home = Cwd::abs_path($ENV{HOME});
        if ($home && $home =~ m{^/} && -d $home) {
            push @paths, File::Spec->catfile($home, '.local', 'bin', 'claude');
            push @paths, File::Spec->catfile($home, '.npm-global', 'bin', 'claude');
        }
    }
    for my $path (@paths) {
        return $path if -x $path;
    }

    Claude::Agent::Error::CLINotFound->throw(
        message => "Could not find 'claude' CLI in PATH or common locations"
    );
    return;
}

my %VERSION_CHECKED;

sub _check_claude_version {
    my ($self, $cli) = @_;

    return if $ENV{CLAUDE_AGENT_SDK_SKIP_VERSION_CHECK};
    return if exists $VERSION_CHECKED{$cli};
    $VERSION_CHECKED{$cli} = undef;

    my $future = $self->_loop->new_future;
    my $ok = eval {
        $self->_loop->run_child(
            command   => [$cli, '-v'],
            on_finish => sub {
                my ($pid, $exitcode, $stdout, $stderr) = @_;
                $future->done($exitcode, $stdout, $stderr) unless $future->is_ready;
            },
        );
        1;
    };
    return unless $ok;
    $self->_await($future, 2);
    return unless $future->is_done;

    my (undef, $stdout) = $future->get;
    return unless defined $stdout && $stdout =~ /(\d+)\.(\d+)\.(\d+)/;
    my $version = "$1.$2.$3";
    $VERSION_CHECKED{$cli} = $version;

    my @have = ($1, $2, $3);
    my @need = split /\./, $MINIMUM_CLAUDE_CODE_VERSION;
    for my $i (0 .. 2) {
        last if $have[$i] > $need[$i];
        next if $have[$i] == $need[$i];
        my $text = "Claude Code $version at $cli is older than $MINIMUM_CLAUDE_CODE_VERSION; some features may not work";
        $log->warning($text);
        warn "$text\n";
        last;
    }
    return;
}

sub cli_version {
    my ($self, $cli) = @_;
    $cli //= $self->_cli_path;
    return defined $cli ? $VERSION_CHECKED{$cli} : undef;
}

sub _encode_arg {
    my ($self, $data) = @_;
    my $json = $self->_jsonl->encode([$data]);
    chomp $json;
    return $json;
}

sub _build_command {
    my ($self, $cli) = @_;

    my $o = $self->options;
    my @cmd = ($cli, '--output-format', 'stream-json', '--verbose');

    if ($o->has_system_prompt) {
        my $sp = $o->system_prompt;
        if (!ref $sp) {
            push @cmd, '--system-prompt', $sp;
        }
        else {
            my $type = $sp->{type}
                // (defined $sp->{preset} ? 'preset' : defined $sp->{path} ? 'file' : defined $sp->{prompt} ? 'custom' : '');
            if ($type eq 'preset') {
                push @cmd, '--append-system-prompt', $sp->{append} if defined $sp->{append} && length $sp->{append};
            }
            elsif ($type eq 'custom') {
                push @cmd, '--system-prompt', $sp->{prompt} // '';
            }
            elsif ($type eq 'file') {
                push @cmd, '--system-prompt-file', $sp->{path};
            }
            else {
                Carp::croak("system_prompt hashref needs a type of preset, custom or file");
            }
        }
    }

    if ($o->has_tools) {
        my $tools = $o->tools;
        if (ref $tools eq 'ARRAY') {
            push @cmd, '--tools', join(',', @$tools);
        }
        elsif (ref $tools eq 'HASH') {
            push @cmd, '--tools', 'default';
        }
    }

    push @cmd, '--allowedTools', join(',', @{$o->allowed_tools})
        if $o->has_allowed_tools && @{$o->allowed_tools};
    push @cmd, '--max-turns', int($o->max_turns) if $o->has_max_turns;
    push @cmd, '--max-budget-usd', $o->max_budget_usd if $o->has_max_budget_usd;
    push @cmd, '--disallowedTools', join(',', @{$o->disallowed_tools})
        if $o->has_disallowed_tools && @{$o->disallowed_tools};
    push @cmd, '--model', $o->model if $o->has_model;
    push @cmd, '--fallback-model', $o->fallback_model if $o->has_fallback_model;
    push @cmd, '--betas', join(',', @{$o->betas}) if $o->has_betas && @{$o->betas};

    if ($o->has_can_use_tool) {
        push @cmd, '--permission-prompt-tool', 'stdio';
    }
    elsif ($o->has_permission_prompt_tool_name) {
        push @cmd, '--permission-prompt-tool', $o->permission_prompt_tool_name;
    }

    push @cmd, '--permission-mode', $o->permission_mode if $o->has_permission_mode;
    push @cmd, '--continue' if $o->has_continue_conversation && $o->continue_conversation;
    push @cmd, '--resume=' . $o->resume if $o->has_resume;
    push @cmd, '--session-id=' . $o->session_id if $o->has_session_id;

    my $settings = $self->_settings_value;
    push @cmd, '--settings', $settings if defined $settings;

    if ($o->has_add_dirs) {
        push @cmd, '--add-dir', $_ for @{$o->add_dirs};
    }

    if ($o->has_mcp_servers && %{$o->mcp_servers}) {
        my %servers;
        for my $name (keys %{$o->mcp_servers}) {
            my $server = $o->mcp_servers->{$name};
            $servers{$name} = blessed($server) && $server->can('to_cli_config') ? $server->to_cli_config
                            : blessed($server) && $server->can('to_hash')       ? $server->to_hash
                            :                                                      $server;
        }
        push @cmd, '--mcp-config', $self->_encode_arg({ mcpServers => \%servers });
    }

    push @cmd, '--include-partial-messages' if $o->has_include_partial_messages && $o->include_partial_messages;
    push @cmd, '--include-hook-events' if $o->has_include_hook_events && $o->include_hook_events;
    push @cmd, '--strict-mcp-config' if $o->has_strict_mcp_config && $o->strict_mcp_config;
    push @cmd, '--fork-session' if $o->has_fork_session && $o->fork_session;
    push @cmd, '--setting-sources=' . join(',', @{$o->setting_sources}) if $o->has_setting_sources;

    if ($o->has_plugins) {
        push @cmd, '--plugin-dir', $_->{path} for @{$o->plugins};
    }

    if ($o->has_extra_args) {
        my $extra = $o->extra_args;
        for my $flag (sort keys %$extra) {
            my $value = $extra->{$flag};
            if (!defined $value) {
                push @cmd, "--$flag";
            }
            elsif ($value =~ /^-/) {
                push @cmd, "--$flag=$value";
            }
            else {
                push @cmd, "--$flag", "$value";
            }
        }
    }

    if ($o->has_thinking) {
        my $thinking = $o->thinking;
        my $type = $thinking->{type} // '';
        if ($type eq 'adaptive') {
            push @cmd, '--thinking', 'adaptive';
        }
        elsif ($type eq 'enabled') {
            push @cmd, '--max-thinking-tokens', int($thinking->{budget_tokens} // 0);
        }
        elsif ($type eq 'disabled') {
            push @cmd, '--thinking', 'disabled';
        }
    }
    elsif ($o->has_max_thinking_tokens) {
        push @cmd, '--max-thinking-tokens', int($o->max_thinking_tokens);
    }

    push @cmd, '--effort', $o->effort if $o->has_effort;

    if ($o->has_output_format && ref $o->output_format eq 'HASH' && $o->output_format->{schema}) {
        push @cmd, '--json-schema', $self->_encode_arg($o->output_format->{schema});
    }

    push @cmd, '--input-format', 'stream-json';
    return @cmd;
}

sub _settings_value {
    my ($self) = @_;
    my $o = $self->options;
    return unless $o->has_settings || $o->has_sandbox;

    my $settings = $o->has_settings ? $o->settings : undef;
    return ref $settings ? $self->_encode_arg($settings) : $settings
        unless $o->has_sandbox;

    my %merged;
    if (ref $settings eq 'HASH') {
        %merged = %$settings;
    }
    elsif (defined $settings && $settings =~ /^\s*\{/) {
        my ($decoded) = $self->_jsonl->decode($settings . "\n");
        %merged = %$decoded if ref $decoded eq 'HASH';
    }
    elsif (defined $settings && -f $settings) {
        open my $fh, '<', $settings or Carp::croak("Cannot read settings file $settings: $!");
        local $/;
        my ($decoded) = $self->_jsonl->decode(scalar(<$fh>) . "\n");
        close $fh;
        %merged = %$decoded if ref $decoded eq 'HASH';
    }
    $merged{sandbox} = $o->sandbox;
    return $self->_encode_arg(\%merged);
}

sub _build_env {
    my ($self) = @_;
    my $o = $self->options;

    my %env = %ENV;
    delete $env{CLAUDECODE};
    $env{CLAUDE_CODE_ENTRYPOINT} = $ENTRYPOINT;
    %env = (%env, %{$o->env}) if $o->has_env;
    $env{CLAUDE_AGENT_SDK_VERSION} = $Claude::Agent::VERSION // 'dev';
    $env{CLAUDE_CODE_SDK_READS_SESSION_STATE} = '1'
        unless exists $env{CLAUDE_CODE_SDK_READS_SESSION_STATE};
    $env{CLAUDE_CODE_ENABLE_SDK_FILE_CHECKPOINTING} = 'true'
        if $o->has_enable_file_checkpointing && $o->enable_file_checkpointing;
    $env{PWD} = $o->cwd if $o->has_cwd;
    return \%env;
}

sub _start_process {
    my ($self) = @_;

    unless ($self->spawn) {
        $self->_initialize;
        return;
    }

    my $cli = $self->_find_claude_cli;
    $self->_cli_path($cli);
    $self->_check_claude_version($cli);

    my $o = $self->options;
    if ($o->has_cwd && !-d $o->cwd) {
        Claude::Agent::Error::ProcessError->throw(
            message => "cwd '" . $o->cwd . "' is not a directory",
        );
    }

    my @cmd = $self->_build_command($cli);
    my $env = $self->_build_env;
    $log->debug(sprintf("Query: starting %s with %d arguments", $cli, scalar(@cmd) - 1));
    $log->trace(sprintf("Query: argv: %s", join(' ', @cmd)));

    my $stderr = $o->has_stderr ? $o->stderr : undef;

    my $process = IO::Async::Process->new(
        command => \@cmd,
        setup   => [
            env => $env,
            ($o->has_cwd ? (chdir => $o->cwd) : ()),
        ],
        stdin  => { via => 'pipe_write' },
        stdout => {
            on_read => sub {
                my ($stream, $buffref) = @_;
                while ($$buffref =~ s/^([^\n]*)\n//) {
                    $self->_handle_line($1);
                }
                return 0;
            },
        },
        stderr => {
            on_read => sub {
                my ($stream, $buffref) = @_;
                while ($$buffref =~ s/^([^\n]*)\n//) {
                    my $line = $1;
                    if ($stderr) { $stderr->($line) } else { $log->debug("Claude CLI stderr: $line") }
                }
                return 0;
            },
        },
        on_finish => sub {
            my ($proc, $exitcode) = @_;
            my $status = $exitcode >> 8;
            $log->debug(sprintf("Query: process finished with exit code %d", $status));
            $self->_error("Claude CLI exited with code $status") if $status != 0 && !$self->_error;
            $self->_on_exit;
        },
        on_exception => sub {
            my ($proc, $exception) = @_;
            $log->debug(sprintf("Query: process exception: %s", $exception));
            $self->_error("Claude CLI exception: $exception");
            $self->_on_exit;
        },
    );

    $self->_process($process);
    $self->_stdin($process->stdin);
    $self->_loop->add($process);

    $self->_initialize;
    return;
}

sub _on_exit {
    my ($self) = @_;
    $self->_finished(1);
    $self->_stdin_closed(1);
    $self->_clear_run_end_timer;
    $self->_exit_future->done unless $self->_exit_future->is_ready;
    $self->_finish_pending;
    return;
}

sub _finish_pending {
    my ($self) = @_;
    my $why = $self->_error // 'Query finished';
    for my $id (keys %{$self->_pending_control}) {
        my $entry = delete $self->_pending_control->{$id};
        $entry->{timer}->cancel if $entry->{timer} && !$entry->{timer}->is_ready;
        $entry->{future}->fail($why) unless $entry->{future}->is_ready;
    }
    for my $id (keys %{$self->_inflight_requests}) {
        my $future = delete $self->_inflight_requests->{$id};
        $future->cancel unless $future->is_ready;
    }
    while (my $future = shift @{$self->_pending_futures}) {
        $future->done(undef) unless $future->is_ready;
    }
    return;
}

sub _initialize {
    my ($self) = @_;

    my %request = (subtype => 'initialize');
    $request{hooks} = $self->_hook_registry ? $self->_hook_registry->to_initialize_config : undef;

    my $o = $self->options;
    if ($o->has_agents && %{$o->agents}) {
        $request{agents} = {
            map {
                my $agent = $o->agents->{$_};
                $_ => (blessed($agent) && $agent->can('to_hash') ? $agent->to_hash : $agent)
            } keys %{$o->agents}
        };
    }
    $request{forwardSubagentText} = \1 if $o->has_forward_subagent_text && $o->forward_subagent_text;

    my $timeout = ($ENV{CLAUDE_CODE_STREAM_CLOSE_TIMEOUT} // 0) / 1000;
    $timeout = 60 if $timeout < 60;

    $self->_send_control_request(\%request, $timeout)->on_done(sub {
        my ($result) = @_;
        $self->_init_result($result);
        $log->debug("Query: initialized");
        $self->_send_prompt;
    })->on_fail(sub {
        my ($err) = @_;
        $log->debug(sprintf("Query: initialize failed: %s", $err));
        $self->_error("initialize failed: $err") unless $self->_error;
        $self->close_async->retain;
    })->retain;
    return;
}

sub _send_prompt {
    my ($self) = @_;

    if ($self->has_prompt) {
        $self->send_user_message($self->prompt);
    }
    $self->_end_input unless $self->_needs_stdin_open;
    return;
}

sub _needs_stdin_open {
    my ($self) = @_;
    return 1 if $self->persistent;
    return 1 if $self->_hook_registry;
    return 1 if %{$self->_sdk_bridges};
    return 1 if $self->options->has_can_use_tool;
    return 0;
}

sub _write {
    my ($self, $data) = @_;

    return 0 if $self->_stdin_closed;
    my $line = $self->_jsonl->encode([$data]);
    return 0 unless defined $line && length $line;

    if ($self->has_writer) {
        $self->writer->($line, $data);
        return 1;
    }
    return 0 unless $self->_stdin;
    my $ok = eval { $self->_stdin->write($line); 1 };
    $log->debug(sprintf("Query: write failed: %s", $@)) unless $ok;
    return $ok ? 1 : 0;
}

sub _end_input {
    my ($self) = @_;
    return if $self->_stdin_closed;
    $self->_stdin_closed(1);
    $log->debug("Query: closing stdin");
    if ($self->has_closer) {
        $self->closer->();
    }
    elsif ($self->_stdin) {
        $self->_stdin->close_when_empty;
    }
    return;
}

sub _send_control_request {
    my ($self, $request, $timeout) = @_;

    $timeout //= 60;
    my $subtype = $request->{subtype} // 'unknown';

    return Future->fail('Query is not running') if $self->_finished || $self->_stdin_closed;

    my $counter = $self->_request_counter + 1;
    $self->_request_counter($counter);
    my $id = sprintf('req_%d_%s', $counter, unpack('H*', Crypt::URandom::urandom(4)));

    my $future = $self->_loop->new_future;
    my $entry = { future => $future };
    $self->_pending_control->{$id} = $entry;

    if ($timeout > 0) {
        $entry->{timer} = $self->_loop->delay_future(after => $timeout)->on_done(sub {
            my $pending = delete $self->_pending_control->{$id} or return;
            $pending->{future}->fail("Control request timeout: $subtype") unless $pending->{future}->is_ready;
        });
    }

    $future->on_ready(sub {
        my $pending = delete $self->_pending_control->{$id};
        $pending->{timer}->cancel if $pending && $pending->{timer} && !$pending->{timer}->is_ready;
    });

    $log->debug(sprintf("Query: control_request %s %s", $subtype, $id));
    unless ($self->_write({ type => 'control_request', request_id => $id, request => $request })) {
        $future->fail("Could not send control request: $subtype") unless $future->is_ready;
    }
    return $future;
}

sub _on_control_response {
    my ($self, $data) = @_;

    my $response = $data->{response};
    return unless ref $response eq 'HASH';
    my $id = $response->{request_id} // '';
    my $entry = delete $self->_pending_control->{$id} or return;
    $entry->{timer}->cancel if $entry->{timer} && !$entry->{timer}->is_ready;
    return if $entry->{future}->is_ready;

    if (($response->{subtype} // '') eq 'error') {
        $entry->{future}->fail($response->{error} // 'unknown error');
    }
    else {
        my $result = $response->{response};
        $entry->{future}->done(ref $result eq 'HASH' ? $result : {});
    }
    return;
}

sub _on_control_request {
    my ($self, $data) = @_;

    my $request_id = $data->{request_id} // '';
    my $request = ref $data->{request} eq 'HASH' ? $data->{request} : {};
    my $subtype = $request->{subtype} // '';

    $log->debug(sprintf("Query: control_request from CLI: %s %s", $subtype, $request_id));

    my $future;
    my $ok = eval {
        $future = $subtype eq 'can_use_tool'  ? $self->_handle_can_use_tool($request)
                : $subtype eq 'hook_callback' ? $self->_handle_hook_callback($request)
                : $subtype eq 'mcp_message'   ? $self->_handle_mcp_message($request)
                : Future->fail("Unsupported control request subtype: $subtype");
        1;
    };
    $future = Future->fail("$@") unless $ok;
    $future = Future->done($future) unless blessed($future) && $future->isa('Future');

    $self->_inflight_requests->{$request_id} = $future;
    $future->on_ready(sub {
        my ($f) = @_;
        return unless delete $self->_inflight_requests->{$request_id};
        return if $f->is_cancelled;
        if ($f->is_failed) {
            my ($err) = $f->failure;
            $log->debug(sprintf("Query: control_request %s failed: %s", $request_id, $err));
            $self->_write({
                type     => 'control_response',
                response => { subtype => 'error', request_id => $request_id, error => "$err" },
            });
        }
        else {
            my ($result) = $f->get;
            $self->_write({
                type     => 'control_response',
                response => { subtype => 'success', request_id => $request_id, response => $result // {} },
            });
        }
    })->retain;
    return;
}

sub _on_control_cancel {
    my ($self, $data) = @_;
    my $id = $data->{request_id} // '';
    my $future = delete $self->_inflight_requests->{$id} or return;
    $log->debug(sprintf("Query: control_request %s cancelled", $id));
    $future->cancel unless $future->is_ready;
    return;
}

sub _handle_can_use_tool {
    my ($self, $request) = @_;

    my $o = $self->options;
    return Future->fail('can_use_tool callback is not provided') unless $o->has_can_use_tool;

    my $tool_name = $request->{tool_name} // '';
    my $input = ref $request->{input} eq 'HASH' ? $request->{input} : {};

    my $context = Claude::Agent::Permission::Context->new(
        tool_name  => $tool_name,
        tool_input => $input,
        Claude::Agent::Types::defined_args(
            session_id      => $self->_session_id,
            cwd             => ($o->has_cwd ? $o->cwd : undef),
            tool_use_id     => $request->{tool_use_id},
            agent_id        => $request->{agent_id},
            suggestions     => $request->{permission_suggestions},
            blocked_path    => $request->{blocked_path},
            decision_reason => $request->{decision_reason},
            title           => $request->{title},
            display_name    => $request->{display_name},
            description     => $request->{description},
            query           => $self,
        ),
    );

    my $result;
    my $ok = eval { $result = $o->can_use_tool->($tool_name, $input, $context); 1 };
    return Future->fail("$@") unless $ok;

    my $future = blessed($result) && $result->isa('Future') ? $result : Future->done($result);
    return $future->then(sub {
        my ($answer) = @_;
        my $permission = Claude::Agent::Permission->coerce($answer)
            or return Future->fail('can_use_tool must return a Claude::Agent::Permission result');
        my $hash = $permission->to_hash;
        $hash->{updatedInput} = $input if $hash->{behavior} eq 'allow' && !exists $hash->{updatedInput};
        $log->debug(sprintf("Query: can_use_tool %s -> %s", $tool_name, $hash->{behavior}));
        return Future->done($hash);
    });
}

sub _handle_hook_callback {
    my ($self, $request) = @_;
    my $registry = $self->_hook_registry
        or return Future->fail('No hooks are registered');
    return $registry->run($request->{callback_id} // '', $request->{input}, $request->{tool_use_id});
}

sub _handle_mcp_message {
    my ($self, $request) = @_;

    my $name = $request->{server_name} // '';
    my $message = $request->{message};
    my $id = ref $message eq 'HASH' ? $message->{id} : undef;

    my $bridge = $self->_sdk_bridges->{$name}
        or return Future->done({ mcp_response => {
            jsonrpc => '2.0', id => $id,
            error   => { code => -32601, message => "Server '$name' not found" },
        } });

    return $bridge->handle($message)->then(sub {
        my ($reply) = @_;
        $reply //= { jsonrpc => '2.0', result => {} };
        return Future->done({ mcp_response => $reply });
    })->else(sub {
        my ($err) = @_;
        return Future->done({ mcp_response => {
            jsonrpc => '2.0', id => $id,
            error   => { code => -32603, message => "$err" },
        } });
    });
}

sub feed_line {
    my ($self, $line) = @_;
    return $self->_handle_line($line);
}

sub _handle_line {
    my ($self, $line) = @_;

    return unless defined $line && length $line;

    my @decoded = $self->_jsonl->decode($line);
    $log->trace(sprintf("Raw line: %s", $line)) if $log->is_trace;

    my $limit = $ENV{CLAUDE_AGENT_JSONL_BUFFER_MAX};
    $limit = 1_000_000 unless defined $limit && $limit =~ /^\d+$/;
    $limit = 100_000 if $limit < 100_000;
    $limit = 10_000_000 if $limit > 10_000_000;
    if ($self->_jsonl->remaining && length($self->_jsonl->remaining) > $limit) {
        $log->debug("JSON::Lines buffer overflow, reinitializing");
        $self->_jsonl($self->_build_jsonl);
    }

    for my $data (@decoded) {
        next unless ref $data eq 'HASH' && defined $data->{type};
        my $type = $data->{type};
        $log->debug(sprintf("Query: received %s%s", $type, defined $data->{subtype} ? "/$data->{subtype}" : ''));

        if ($type eq 'control_response')      { $self->_on_control_response($data); next }
        if ($type eq 'control_request')       { $self->_on_control_request($data);  next }
        if ($type eq 'control_cancel_request') { $self->_on_control_cancel($data);  next }
        next if $CONSUMED{$type};

        if ($type eq 'system' && ($data->{subtype} // '') eq 'session_state_changed') {
            $self->_on_session_state($data->{state});
            next if $data->{sdk_host_only};
        }

        my $msg = eval { Claude::Agent::Message->from_json($data) };
        unless ($msg) {
            $log->debug(sprintf("Query: could not parse %s message: %s", $type, $@));
            next;
        }

        if ($type eq 'system' && $msg->subtype eq 'init') {
            $self->_session_id($msg->get_session_id);
            $log->debug(sprintf("Query: session %s", $self->_session_id // 'none'));
        }
        elsif ($type eq 'result') {
            $self->_on_result;
        }
        elsif (($type eq 'assistant' || $type eq 'stream_event') && !$msg->has_parent_tool_use_id) {
            if ($self->_result_received) {
                $self->_result_received(0);
                $self->_clear_run_end_timer;
            }
            $self->_turn_in_progress(1);
        }

        $self->_deliver($msg);
    }
    return;
}

sub _deliver {
    my ($self, $msg) = @_;

    if ($self->_processing_message) {
        push @{$self->_messages}, $msg;
        return;
    }
    $self->_processing_message(1);
    if (@{$self->_pending_futures}) {
        my $future = shift @{$self->_pending_futures};
        $future->done($msg);
    }
    else {
        push @{$self->_messages}, $msg;
    }
    $self->_processing_message(0);
    return;
}

sub _on_result {
    my ($self) = @_;
    $self->_result_received(1);
    $self->_turn_in_progress(0);
    return if $self->persistent || !$self->_needs_stdin_open;

    my $state = $self->_session_state;
    if (!defined $state || $state eq 'idle') {
        $self->_end_run;
    }
    elsif ($state ne 'requires_action') {
        $self->_arm_run_end_ceiling;
    }
    return;
}

sub _on_session_state {
    my ($self, $state) = @_;
    $self->_session_state($state);
    return unless $self->_result_received && !$self->_turn_in_progress;
    return if $self->persistent || !$self->_needs_stdin_open;
    $state //= '';
    if ($state eq 'idle') {
        $self->_end_run;
    }
    elsif ($state eq 'requires_action') {
        $self->_clear_run_end_timer;
    }
    elsif ($state eq 'running') {
        $self->_arm_run_end_ceiling;
    }
    return;
}

sub _run_end_ceiling_ms {
    my ($self) = @_;
    my $o = $self->options;
    my $ms = $o->has_env ? $o->env->{CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS} : undef;
    $ms //= $ENV{CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS};
    $ms = 600_000 unless defined $ms && $ms =~ /^\d+$/;
    return $ms;
}

sub _arm_run_end_ceiling {
    my ($self) = @_;
    $self->_clear_run_end_timer;
    my $ms = $self->_run_end_ceiling_ms;
    return if $ms == 0;
    $self->_run_end_timer($self->_loop->delay_future(after => $ms / 1000)->on_done(sub {
        $log->debug("Query: run end ceiling reached, closing stdin");
        $self->_end_run;
    }));
    return;
}

sub _clear_run_end_timer {
    my ($self) = @_;
    my $timer = $self->_run_end_timer or return;
    $timer->cancel unless $timer->is_ready;
    $self->_run_end_timer(undef);
    return;
}

sub _end_run {
    my ($self) = @_;
    $self->_clear_run_end_timer;
    $self->_end_input;
    return;
}

sub _await {
    my ($self, $future, $timeout) = @_;
    $timeout //= 60;
    my $deadline = Time::HiRes::time() + $timeout;
    while (!$future->is_ready && Time::HiRes::time() < $deadline) {
        $self->_loop->loop_once(0.05);
    }
    $future->cancel unless $future->is_ready;
    return $future;
}

sub _sync {
    my ($self, $future, $timeout) = @_;
    $self->_await($future, $timeout);
    return $future->get if $future->is_done;
    $log->debug(sprintf("Query: request failed: %s", $future->is_failed ? scalar $future->failure : 'timed out'));
    return;
}

sub send_user_message {
    my ($self, $content, %args) = @_;

    return 0 if $self->_finished;
    my $ok = $self->_write({
        type               => 'user',
        session_id         => $args{session_id} // '',
        message            => { role => 'user', content => $content },
        parent_tool_use_id => undef,
    });
    if ($ok) {
        $self->_result_received(0);
        $self->_turn_in_progress(1);
        $self->_clear_run_end_timer;
    }
    return $ok;
}

sub interrupt_async {
    my ($self) = @_;
    return $self->_send_control_request({ subtype => 'interrupt' });
}

sub set_permission_mode_async {
    my ($self, $mode) = @_;
    return $self->_send_control_request({ subtype => 'set_permission_mode', mode => $mode });
}

sub set_model_async {
    my ($self, $model) = @_;
    return $self->_send_control_request({ subtype => 'set_model', model => $model });
}

sub set_max_thinking_tokens_async {
    my ($self, $tokens) = @_;
    return $self->_send_control_request({ subtype => 'set_max_thinking_tokens', max_thinking_tokens => $tokens });
}

sub rewind_files_async {
    my ($self, $user_message_uuid) = @_;
    return $self->_send_control_request({ subtype => 'rewind_files', user_message_id => $user_message_uuid });
}

sub mcp_status_async {
    my ($self) = @_;
    return $self->_send_control_request({ subtype => 'mcp_status' });
}

sub get_context_usage_async {
    my ($self) = @_;
    return $self->_send_control_request({ subtype => 'get_context_usage' });
}

sub reconnect_mcp_server_async {
    my ($self, $name) = @_;
    return $self->_send_control_request({ subtype => 'mcp_reconnect', serverName => $name });
}

sub toggle_mcp_server_async {
    my ($self, $name, $enabled) = @_;
    return $self->_send_control_request({ subtype => 'mcp_toggle', serverName => $name, enabled => ($enabled ? \1 : \0) });
}

sub stop_task_async {
    my ($self, $task_id) = @_;
    return $self->_send_control_request({ subtype => 'stop_task', task_id => $task_id });
}

sub interrupt               { my $self = shift; return $self->_sync($self->interrupt_async(@_)) }
sub set_permission_mode     { my $self = shift; return $self->_sync($self->set_permission_mode_async(@_)) }
sub set_model               { my $self = shift; return $self->_sync($self->set_model_async(@_)) }
sub set_max_thinking_tokens { my $self = shift; return $self->_sync($self->set_max_thinking_tokens_async(@_)) }
sub rewind_files            { my $self = shift; return $self->_sync($self->rewind_files_async(@_)) }
sub mcp_status              { my $self = shift; return $self->_sync($self->mcp_status_async(@_)) }
sub get_context_usage       { my $self = shift; return $self->_sync($self->get_context_usage_async(@_)) }
sub reconnect_mcp_server    { my $self = shift; return $self->_sync($self->reconnect_mcp_server_async(@_)) }
sub toggle_mcp_server       { my $self = shift; return $self->_sync($self->toggle_mcp_server_async(@_)) }
sub stop_task               { my $self = shift; return $self->_sync($self->stop_task_async(@_)) }

sub server_info {
    my ($self) = @_;
    return $self->_init_result;
}

sub supported_commands {
    my ($self) = @_;
    my $info = $self->_init_result or return;
    return $info->{commands} // $info->{supportedCommands};
}

sub supported_models {
    my ($self) = @_;
    my $info = $self->_init_result or return;
    return $info->{models} // $info->{supportedModels};
}

sub output_style {
    my ($self) = @_;
    my $info = $self->_init_result or return;
    return $info->{output_style} // $info->{outputStyle};
}

sub available_output_styles {
    my ($self) = @_;
    my $info = $self->_init_result or return;
    return $info->{available_output_styles} // $info->{availableOutputStyles};
}

sub session_id  { $_[0]->_session_id }
sub is_finished { $_[0]->_finished }
sub error       { $_[0]->_error }

sub next {
    my ($self) = @_;

    return shift @{$self->_messages} if @{$self->_messages};

    my $timeout = $self->options->query_timeout // 600;
    $timeout = 600 if $timeout <= 0 || $timeout > 3600;
    my $deadline = Time::HiRes::time() + $timeout;

    while (!@{$self->_messages} && !$self->_finished && Time::HiRes::time() < $deadline) {
        $self->_loop->loop_once(0.1);
    }

    return shift @{$self->_messages} if @{$self->_messages};
    return if $self->_finished;

    $self->_error("Query timed out after $timeout seconds");
    $log->debug(sprintf("Query: timed out after %d seconds", $timeout));
    return;
}

sub next_async {
    my ($self) = @_;

    return Future->done(shift @{$self->_messages}) if @{$self->_messages};
    return Future->done(undef) if $self->_finished;

    my $future = $self->_loop->new_future;
    push @{$self->_pending_futures}, $future;
    return $future;
}

sub close_async {
    my ($self) = @_;

    return Future->done if $self->_closed;
    $self->_closed(1);
    $self->_clear_run_end_timer;

    if (!$self->_process || $self->_finished) {
        $self->_end_input;
        $self->_finished(1);
        $self->_finish_pending;
        return Future->done;
    }

    my $loop = $self->_loop;
    my $wait = sub {
        my ($secs) = @_;
        return Future->done if $self->_finished;
        return Future->wait_any($self->_exit_future, $loop->delay_future(after => $secs));
    };
    my $signal = sub {
        my ($sig) = @_;
        return if $self->_finished;
        $log->debug("Query: sending SIG$sig");
        eval { $self->_process->kill($sig) };
        return;
    };

    return $self->_send_control_request({ subtype => 'interrupt' }, 2)
        ->else(sub { Future->done })
        ->then(sub { $self->_end_input; $wait->(5) })
        ->then(sub { $signal->('INT');  $wait->(5) })
        ->then(sub { $signal->('TERM'); $wait->(5) })
        ->then(sub { $signal->('KILL'); $wait->(1) })
        ->then(sub {
            $self->_finish_pending;
            return Future->done;
        });
}

sub close {
    my ($self) = @_;
    $self->_await($self->close_async, 20);
    return;
}

sub cleanup {
    my ($self) = @_;
    return $self->close;
}

1;

__END__

=head1 NAME

Claude::Agent::Query - One conversation with the Claude Code CLI

=head1 SYNOPSIS

    use Claude::Agent::Query;
    use Claude::Agent::Options;

    my $query = Claude::Agent::Query->new(
        prompt  => "Find all TODO comments",
        options => Claude::Agent::Options->new(
            allowed_tools => ['Read', 'Glob', 'Grep'],
        ),
    );

    while (my $msg = $query->next) {
        if ($msg->isa('Claude::Agent::Message::Result')) {
            print $msg->result, "\n";
            last;
        }
    }

    my $future = $query->next_async;

=head1 DESCRIPTION

A query starts the C<claude> CLI as a child process, speaks the SDK control
protocol with it over its standard streams, and delivers the messages it
emits as L<Claude::Agent::Message> objects. The C<query()> function of
L<Claude::Agent> builds one.

The CLI is started with C<--output-format stream-json --input-format
stream-json>. The first thing written to it is an C<initialize> control
request carrying the hook registrations and agent definitions; the prompt
is written as a user message once the CLI has answered. Hooks,
C<can_use_tool> and in-process MCP servers are served from the CLI's
C<control_request> messages. Standard input is closed as soon as the
prompt is sent unless one of those is in use, in which case it stays open
until the turn's result arrives and the CLI reports itself idle.

=head1 ATTRIBUTES

=head2 prompt

The first user message: a string, or an ArrayRef of content blocks. May be
left unset for a session that will send its first message later.

=head2 options

A L<Claude::Agent::Options>. Defaults to an empty one.

=head2 loop

An L<IO::Async::Loop> to run on. One is created when none is given; pass
your application's loop for event-driven use.

=head2 persistent

Keep standard input open across turns. L<Claude::Agent::Client> sets it.

=head2 spawn, writer, closer

Test seams. With C<spawn =E<gt> 0> no process is started: every line that
would go to the CLI is passed to C<writer> as C<($line, $data)>, closing
standard input calls C<closer>, and C<feed_line> injects the CLI's output.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored. The CLI
is located (C<cli_path>, C<PATH>, then the usual install locations) and
started before C<new> returns; a CLI older than
C<$Claude::Agent::Query::MINIMUM_CLAUDE_CODE_VERSION> is warned about.
Set C<CLAUDE_AGENT_SDK_SKIP_VERSION_CHECK> to skip the probe.

=head2 next

    my $msg = $query->next;

Blocks until the next message, returning undef when the process has
finished. Waits at most the C<query_timeout> option (default 600 seconds)
and then records a timeout in C<error>.

=head2 next_async

    my $msg = await $query->next_async;

A L<Future> of the next message, resolving to undef when the process has
finished.

=head2 send_user_message

    $query->send_user_message("Continue", session_id => $id);

Write a user message. Returns true when written.

=head2 interrupt, interrupt_async

Ask the CLI to stop the current turn.

=head2 set_permission_mode, set_permission_mode_async

    $query->set_permission_mode('acceptEdits');

=head2 set_model, set_model_async

    $query->set_model('sonnet');

=head2 set_max_thinking_tokens, set_max_thinking_tokens_async

    $query->set_max_thinking_tokens(8000);

=head2 rewind_files, rewind_files_async

    $query->rewind_files($result->user_message_uuid);

Undo file changes back to a prompt. Needs the
C<enable_file_checkpointing> option.

=head2 mcp_status, mcp_status_async

The CLI's MCP server status report.

=head2 get_context_usage, get_context_usage_async

The CLI's context window usage breakdown.

=head2 reconnect_mcp_server, reconnect_mcp_server_async

    $query->reconnect_mcp_server('github');

Ask the CLI to reconnect an MCP server.

=head2 toggle_mcp_server, toggle_mcp_server_async

    $query->toggle_mcp_server('github', 0);

Enable or disable an MCP server for the session.

=head2 stop_task, stop_task_async

    $query->stop_task($task_id);

Stop a background task.

Every C<_async> method returns a L<Future> of the CLI's response hash,
failing with the CLI's error text, on timeout (60 seconds), or when the
query is not running. The plain form runs the loop until the Future is
ready and returns the response, or undef on failure.

=head2 server_info

The CLI's answer to the C<initialize> request, once the query has started.
On Claude Code 2.1.300 it carries C<commands>, C<models>, C<output_style>,
C<available_output_styles>, C<account>, C<capabilities>,
C<claude_code_version>, C<current_permission_mode>, C<session_state>,
C<fast_mode_state> and C<pid>.

=head2 supported_commands, supported_models, output_style, available_output_styles

Fields of C<server_info>.

=head2 session_id

The session id, once the CLI's init message has arrived.

=head2 cli_version

    my $version = $query->cli_version;

The version the C<claude -v> probe reported for the CLI in use, if it
ran. Takes an optional path to ask about another CLI.

=head2 is_finished

True once the process has exited.

=head2 error

The error text if the process failed, timed out, or could not initialize.

=head2 close, close_async

    $query->close;

Stop the process: an interrupt request, then standard input is closed,
then SIGINT, SIGTERM and SIGKILL at five second intervals until it exits.
Pending Futures are resolved.

=head2 cleanup

An alias for C<close>, kept from 0.13.

=head2 feed_line

    $query->feed_line($json);

Process one line as if the CLI had written it. A test seam.

=head1 ENVIRONMENT

The child inherits the environment with C<CLAUDECODE> removed and
C<CLAUDE_CODE_ENTRYPOINT>, C<CLAUDE_AGENT_SDK_VERSION> and
C<CLAUDE_CODE_SDK_READS_SESSION_STATE> set; the C<env> option is applied
over it. C<CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS> (default 600000, 0 for
none) bounds how long standard input stays open after a result while the
CLI still reports background work. C<CLAUDE_AGENT_JSONL_BUFFER_MAX> caps
the partial-line buffer.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

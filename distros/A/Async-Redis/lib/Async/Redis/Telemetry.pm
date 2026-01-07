package Async::Redis::Telemetry;

use strict;
use warnings;
use 5.018;

use Time::HiRes qw(time);

our $VERSION = '0.001';

# Commands with sensitive arguments that need redaction
our %REDACT_RULES = (
    AUTH => sub {
        my (@args) = @_;
        if (@args == 1) {
            # AUTH password
            return ('[REDACTED]');
        }
        elsif (@args >= 2) {
            # AUTH username password
            return ($args[0], '[REDACTED]');
        }
        return @args;
    },

    CONFIG => sub {
        my (@args) = @_;
        return @args unless @args >= 3;

        my $subcommand = uc($args[0] // '');
        if ($subcommand eq 'SET') {
            my $param = lc($args[1] // '');
            if ($param =~ /^(requirepass|masterauth|masteruser|user)$/) {
                return ($args[0], $args[1], '[REDACTED]');
            }
        }
        return @args;
    },

    MIGRATE => sub {
        my (@args) = @_;
        my @result;

        for (my $i = 0; $i <= $#args; $i++) {
            my $arg = $args[$i];
            my $uc_arg = uc($arg // '');

            if ($uc_arg eq 'AUTH' && defined $args[$i + 1]) {
                push @result, $arg, '[REDACTED]';
                $i++;  # Skip password
            }
            elsif ($uc_arg eq 'AUTH2' && defined $args[$i + 1] && defined $args[$i + 2]) {
                push @result, $arg, $args[$i + 1], '[REDACTED]';
                $i += 2;  # Skip username and password
            }
            else {
                push @result, $arg;
            }
        }

        return @result;
    },

    HELLO => sub {
        my (@args) = @_;
        my @result;

        for (my $i = 0; $i <= $#args; $i++) {
            my $arg = $args[$i];
            my $uc_arg = uc($arg // '');

            if ($uc_arg eq 'AUTH' && defined $args[$i + 1] && defined $args[$i + 2]) {
                push @result, $arg, $args[$i + 1], '[REDACTED]';
                $i += 2;  # Skip username and password
            }
            else {
                push @result, $arg;
            }
        }

        return @result;
    },

    ACL => sub {
        my (@args) = @_;
        return @args unless @args >= 1;

        my $subcommand = uc($args[0] // '');
        if ($subcommand eq 'SETUSER' && @args >= 3) {
            # ACL SETUSER username ...rules...
            # Redact any >password patterns
            my @result = ($args[0], $args[1]);
            for my $i (2 .. $#args) {
                if ($args[$i] =~ /^>/) {
                    push @result, '>[REDACTED]';
                }
                else {
                    push @result, $args[$i];
                }
            }
            return @result;
        }
        return @args;
    },
);

# Format command for logging with redaction
sub format_command_for_log {
    my (@cmd) = @_;

    return '' unless @cmd;

    my $name = uc($cmd[0] // '');
    my @args = @cmd[1 .. $#cmd];

    if (my $redactor = $REDACT_RULES{$name}) {
        @args = $redactor->(@args);
    }

    return join(' ', $name, @args);
}

# Format command for OTel span (same redaction, optional args)
sub format_command_for_span {
    my ($include_args, $redact, @cmd) = @_;

    return '' unless @cmd;

    my $name = uc($cmd[0] // '');

    return $name unless $include_args;

    my @args = @cmd[1 .. $#cmd];

    if ($redact && (my $redactor = $REDACT_RULES{$name})) {
        @args = $redactor->(@args);
    }

    return join(' ', $name, @args);
}

#
# OpenTelemetry Integration
#

sub new {
    my ($class, %args) = @_;

    return bless {
        tracer           => $args{tracer},         # OTel tracer
        meter            => $args{meter},          # OTel meter
        debug            => $args{debug},          # Debug logger
        include_args     => $args{include_args} // 1,
        redact           => $args{redact} // 1,
        host             => $args{host} // 'localhost',
        port             => $args{port} // 6379,
        database         => $args{database} // 0,

        # Metrics (lazy-initialized)
        _commands_counter   => undef,
        _commands_histogram => undef,
        _connections_gauge  => undef,
        _errors_counter     => undef,
        _reconnects_counter => undef,
        _pipeline_histogram => undef,
    }, $class;
}

# Initialize metrics (call after meter is set)
sub _init_metrics {
    my ($self) = @_;

    return unless $self->{meter};
    return if $self->{_metrics_initialized};

    my $meter = $self->{meter};

    $self->{_commands_counter} = $meter->create_counter(
        name        => 'redis.commands.total',
        description => 'Total Redis commands executed',
        unit        => '1',
    );

    $self->{_commands_histogram} = $meter->create_histogram(
        name        => 'redis.commands.duration',
        description => 'Redis command latency',
        unit        => 'ms',
    );

    $self->{_connections_gauge} = $meter->create_up_down_counter(
        name        => 'redis.connections.active',
        description => 'Current active connections',
        unit        => '1',
    );

    $self->{_errors_counter} = $meter->create_counter(
        name        => 'redis.errors.total',
        description => 'Total Redis errors by type',
        unit        => '1',
    );

    $self->{_reconnects_counter} = $meter->create_counter(
        name        => 'redis.reconnects.total',
        description => 'Total reconnection attempts',
        unit        => '1',
    );

    $self->{_pipeline_histogram} = $meter->create_histogram(
        name        => 'redis.pipeline.size',
        description => 'Commands per pipeline',
        unit        => '1',
    );

    $self->{_metrics_initialized} = 1;
}

# Start a span for a command
sub start_command_span {
    my ($self, @cmd) = @_;

    my $command_name = uc($cmd[0] // 'UNKNOWN');
    my $span;

    if ($self->{tracer}) {
        my $span_name = "redis.$command_name";

        my $statement = format_command_for_span(
            $self->{include_args},
            $self->{redact},
            @cmd
        );

        $span = $self->{tracer}->create_span(
            name       => $span_name,
            kind       => 'client',
            attributes => {
                'db.system'              => 'redis',
                'db.operation'           => $command_name,
                'db.statement'           => $statement,
                'net.peer.name'          => $self->{host},
                'net.peer.port'          => $self->{port},
                'db.redis.database_index' => $self->{database},
            },
        );
    }

    # Always return a context for metrics tracking
    return {
        span       => $span,
        start_time => time(),
        command    => $command_name,
    };
}

# End a command span
sub end_command_span {
    my ($self, $context, $error) = @_;

    return unless $context;

    my $elapsed_ms = (time() - $context->{start_time}) * 1000;

    # Record metrics (always, regardless of span)
    $self->_record_command_metrics($context->{command}, $elapsed_ms, $error);

    # End span if present
    if ($context->{span}) {
        if ($error) {
            $context->{span}->set_status('error', "$error");
            $context->{span}->record_exception($error);
        }
        $context->{span}->end;
    }
}

# Record command metrics
sub _record_command_metrics {
    my ($self, $command, $elapsed_ms, $error) = @_;

    $self->_init_metrics;

    my %labels = (command => $command);

    if ($self->{_commands_counter}) {
        $self->{_commands_counter}->add(1, \%labels);
    }

    if ($self->{_commands_histogram}) {
        $self->{_commands_histogram}->record($elapsed_ms, \%labels);
    }

    if ($error && $self->{_errors_counter}) {
        my $error_type = ref($error) || 'unknown';
        $error_type =~ s/.*:://;  # Strip package prefix
        $self->{_errors_counter}->add(1, { type => $error_type });
    }
}

# Record pipeline metrics
sub record_pipeline {
    my ($self, $size, $elapsed_ms) = @_;

    $self->_init_metrics;

    if ($self->{_pipeline_histogram}) {
        $self->{_pipeline_histogram}->record($size);
    }

    if ($self->{_commands_histogram}) {
        $self->{_commands_histogram}->record($elapsed_ms, { command => 'PIPELINE' });
    }
}

# Record connection event
sub record_connection {
    my ($self, $delta) = @_;

    $self->_init_metrics;

    if ($self->{_connections_gauge}) {
        $self->{_connections_gauge}->add($delta);
    }
}

# Record reconnection attempt
sub record_reconnect {
    my ($self) = @_;

    $self->_init_metrics;

    if ($self->{_reconnects_counter}) {
        $self->{_reconnects_counter}->add(1);
    }
}

#
# Debug Logging
#

sub log_send {
    my ($self, @cmd) = @_;

    return unless $self->{debug};

    my $formatted = format_command_for_log(@cmd);

    if (ref $self->{debug} eq 'CODE') {
        $self->{debug}->('send', $formatted);
    }
    else {
        warn "[REDIS SEND] $formatted\n";
    }
}

sub log_recv {
    my ($self, $result, $elapsed_ms) = @_;

    return unless $self->{debug};

    my $summary = _summarize_result($result);
    my $msg = sprintf("[REDIS RECV] %s (%.2fms)", $summary, $elapsed_ms);

    if (ref $self->{debug} eq 'CODE') {
        $self->{debug}->('recv', $msg);
    }
    else {
        warn "$msg\n";
    }
}

sub log_error {
    my ($self, $error) = @_;

    return unless $self->{debug};

    my $msg = "[REDIS ERROR] $error";

    if (ref $self->{debug} eq 'CODE') {
        $self->{debug}->('error', $msg);
    }
    else {
        warn "$msg\n";
    }
}

sub log_event {
    my ($self, $event, $details) = @_;

    return unless $self->{debug};

    my $msg = "[REDIS EVENT] $event" . ($details ? ": $details" : '');

    if (ref $self->{debug} eq 'CODE') {
        $self->{debug}->('event', $msg);
    }
    else {
        warn "$msg\n";
    }
}

# Summarize result without exposing values
sub _summarize_result {
    my ($result) = @_;

    return 'nil' unless defined $result;

    if (ref $result eq 'ARRAY') {
        return 'array[' . scalar(@$result) . ']';
    }
    elsif (ref $result eq 'HASH') {
        return 'hash{' . scalar(keys %$result) . '}';
    }
    elsif (ref $result && $result->can('message')) {
        return 'error: ' . $result->message;
    }
    elsif (length($result) > 100) {
        return 'string[' . length($result) . ' bytes]';
    }
    else {
        # Short strings are OK to show type
        return 'OK' if $result eq 'OK';
        return 'PONG' if $result eq 'PONG';
        return 'QUEUED' if $result eq 'QUEUED';
        return 'integer' if $result =~ /^-?\d+$/;
        return 'string[' . length($result) . ']';
    }
}

1;

__END__

=head1 NAME

Async::Redis::Telemetry - Observability for Redis client

=head1 SYNOPSIS

    use Async::Redis;
    use OpenTelemetry;

    my $redis = Async::Redis->new(
        host => 'localhost',

        # OpenTelemetry integration
        otel_tracer => OpenTelemetry->tracer_provider->tracer('redis'),
        otel_meter  => OpenTelemetry->meter_provider->meter('redis'),

        # Debug logging
        debug => 1,                    # log to STDERR
        debug => sub {                 # custom logger
            my ($direction, $data) = @_;
            $logger->debug("[$direction] $data");
        },
    );

=head1 DESCRIPTION

Provides OpenTelemetry tracing, metrics collection, and debug logging
with automatic credential redaction.

=head2 Credential Redaction

Sensitive commands are automatically redacted in logs and traces:

=over 4

=item * AUTH password -> AUTH [REDACTED]

=item * AUTH user pass -> AUTH user [REDACTED]

=item * CONFIG SET requirepass x -> CONFIG SET requirepass [REDACTED]

=item * MIGRATE ... AUTH pass -> MIGRATE ... AUTH [REDACTED]

=back

=head2 Metrics

=over 4

=item * redis.commands.total - Counter by command name

=item * redis.commands.duration - Histogram of latency

=item * redis.connections.active - Gauge of current connections

=item * redis.errors.total - Counter by error type

=item * redis.reconnects.total - Counter of reconnect attempts

=item * redis.pipeline.size - Histogram of pipeline batch sizes

=back

=cut

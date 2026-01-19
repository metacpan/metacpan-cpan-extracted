package Async::Redis::Pipeline;

use strict;
use warnings;
use 5.018;

use Future::AsyncAwait;

sub new {
    my ($class, %args) = @_;

    return bless {
        redis     => $args{redis},
        commands  => [],
        executed  => 0,
        max_depth => $args{max_depth} // 10000,
    }, $class;
}

# Queue a command - returns self for chaining
sub _queue {
    my ($self, $cmd, @args) = @_;

    die "Pipeline already executed" if $self->{executed};

    if (@{$self->{commands}} >= $self->{max_depth}) {
        die "Pipeline depth limit ($self->{max_depth}) exceeded";
    }

    push @{$self->{commands}}, [$cmd, @args];
    return $self;
}

# Generate AUTOLOAD to capture any command call
our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $cmd = $AUTOLOAD;
    $cmd =~ s/.*:://;
    return if $cmd eq 'DESTROY';

    return $self->_queue(uc($cmd), @_);
}

# Allow explicit command() calls
sub command {
    my ($self, $cmd, @args) = @_;
    return $self->_queue($cmd, @args);
}

# Explicit add() for backwards compatibility
sub add {
    my ($self, @cmd) = @_;
    return $self->_queue(@cmd);
}

# Queue a registered script by name
# Usage: $pipe->run_script('name', @keys_then_args)
sub run_script {
    my ($self, $name, @args) = @_;

    die "Pipeline already executed" if $self->{executed};
    die "Script name required" unless defined $name;

    if (@{$self->{commands}} >= $self->{max_depth}) {
        die "Pipeline depth limit ($self->{max_depth}) exceeded";
    }

    # Queue with special marker - resolved at execute time
    push @{$self->{commands}}, ['__SCRIPT__', $name, @args];
    return $self;
}

async sub execute {
    my ($self) = @_;

    # Mark as executed (single-use)
    if ($self->{executed}) {
        return [];
    }
    $self->{executed} = 1;

    my @commands = @{$self->{commands}};
    return [] unless @commands;

    my $redis = $self->{redis};

    # Resolve __SCRIPT__ entries to EVALSHA commands
    my %scripts_used;
    for my $cmd (@commands) {
        if ($cmd->[0] eq '__SCRIPT__') {
            my (undef, $name, @args) = @$cmd;

            my $script = $redis->get_script($name)
                or die "Unknown script '$name' in pipeline - use define_command() first";

            $scripts_used{$name} = $script;

            my $num_keys = $script->num_keys;
            if ($num_keys eq 'dynamic') {
                $num_keys = shift @args;
                die "Key count required as first argument for dynamic script '$name'"
                    unless defined $num_keys;
            }

            # Convert to EVALSHA command
            @$cmd = ('EVALSHA', $script->sha, $num_keys, @args);
        }
    }

    # Preload any scripts used (ensures EVALSHA will work)
    for my $script (values %scripts_used) {
        await $redis->script_load($script->script);
    }

    # Apply key prefixing if configured
    if (defined $redis->{prefix} && $redis->{prefix} ne '') {
        require Async::Redis::KeyExtractor;
        for my $cmd (@commands) {
            my ($name, @args) = @$cmd;
            @args = Async::Redis::KeyExtractor::apply_prefix(
                $redis->{prefix}, $name, @args
            );
            @$cmd = ($name, @args);
        }
    }

    # Execute pipeline via Redis connection
    return await $redis->_execute_pipeline(\@commands);
}

sub count { scalar @{shift->{commands}} }

1;

__END__

=head1 NAME

Async::Redis::Pipeline - Command pipelining

=head1 SYNOPSIS

    my $pipe = $redis->pipeline;
    $pipe->set('key1', 'value1');
    $pipe->set('key2', 'value2');
    $pipe->get('key1');

    my $results = await $pipe->execute;
    # $results = ['OK', 'OK', 'value1']

    # Or chained style:
    my $results = await $redis->pipeline
        ->set('a', 1)
        ->get('a')
        ->execute;

=head1 DESCRIPTION

Pipeline collects multiple Redis commands and executes them in a single
network round-trip, significantly reducing latency for bulk operations.

=head2 Error Handling

Two distinct failure modes:

1. **Command-level Redis errors** (WRONGTYPE, OOM): Captured inline in
   result array. Pipeline continues. Check each slot for Error objects.

2. **Transport failures** (connection loss, timeout): Entire pipeline
   fails. Cannot determine which commands succeeded.

=head1 METHODS

=head2 new

    my $pipe = Async::Redis::Pipeline->new(
        redis     => $redis_client,
        max_depth => 10000,
    );

Create a new pipeline. Usually called via C<< $redis->pipeline >>.

=head2 command

    $pipe->command('SET', 'key', 'value');

Queue a command explicitly.

=head2 AUTOLOAD

Any Redis command can be called directly:

    $pipe->set('key', 'value');
    $pipe->hset('hash', 'field', 'value');
    $pipe->lpush('list', 'item');

=head2 execute

    my $results = await $pipe->execute;

Execute all queued commands and return results array.

=head2 run_script

    $pipe->run_script('my_script', @keys_then_args);

Queue a registered Lua script by name. The script must be registered
via C<< $redis->define_command() >> before use.

For scripts with fixed key count:

    $pipe->run_script('publish_msg', 'topic:chat', $message);

For scripts with dynamic key count (first arg is key count):

    $pipe->run_script('dynamic_script', 2, 'key1', 'key2', 'arg1');

Scripts are automatically preloaded before pipeline execution to ensure
EVALSHA succeeds.

=head2 count

    my $n = $pipe->count;

Return number of queued commands.

=cut

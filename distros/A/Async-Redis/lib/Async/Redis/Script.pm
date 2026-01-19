package Async::Redis::Script;

use strict;
use warnings;
use 5.018;

use Future::AsyncAwait;
use Digest::SHA qw(sha1_hex);

sub new {
    my ($class, %args) = @_;

    my $script = $args{script};
    die "Script code required" unless defined $script;

    return bless {
        redis       => $args{redis},
        script      => $script,
        sha         => lc(sha1_hex($script)),
        name        => $args{name},
        num_keys    => $args{num_keys} // 'dynamic',
        description => $args{description},
    }, $class;
}

# Accessors
sub sha         { shift->{sha} }
sub script      { shift->{script} }
sub name        { shift->{name} }
sub num_keys    { shift->{num_keys} }
sub description { shift->{description} }
sub redis       { shift->{redis} }

# Preferred entry point: run with explicit keys and args arrays
# Usage: $script->run(\@keys, \@args)
async sub run {
    my ($self, $keys_aref, $args_aref) = @_;

    $keys_aref //= [];
    $args_aref //= [];

    my $numkeys = scalar @$keys_aref;
    return await $self->call_with_keys($numkeys, @$keys_aref, @$args_aref);
}

# Run on a specific connection (for pipeline/pool support)
# Usage: $script->run_on($redis, \@keys, \@args)
async sub run_on {
    my ($self, $redis, $keys_aref, $args_aref) = @_;

    $keys_aref //= [];
    $args_aref //= [];

    my $numkeys = scalar @$keys_aref;

    return await $redis->evalsha_or_eval(
        $self->{sha},
        $self->{script},
        $numkeys,
        @$keys_aref,
        @$args_aref,
    );
}

# Legacy: call with automatic key count detection
# Usage: $script->call('arg1', 'arg2')
# Assumes all args are ARGV (no KEYS)
async sub call {
    my ($self, @args) = @_;
    return await $self->call_with_keys(0, @args);
}

# Legacy: call with explicit key count
# Usage: $script->call_with_keys($numkeys, @keys, @args)
async sub call_with_keys {
    my ($self, $numkeys, @keys_and_args) = @_;

    my $redis = $self->{redis}
        or die "No Redis connection - use run_on() or pass redis to constructor";

    return await $redis->evalsha_or_eval(
        $self->{sha},
        $self->{script},
        $numkeys,
        @keys_and_args,
    );
}

1;

__END__

=head1 NAME

Async::Redis::Script - Reusable Lua script wrapper with EVALSHA optimization

=head1 SYNOPSIS

    # Create via redis->script()
    my $script = $redis->script(<<'LUA');
        local current = redis.call('GET', KEYS[1]) or 0
        return current + ARGV[1]
    LUA

    # Preferred: run() with explicit keys and args arrays
    my $result = await $script->run(['mykey'], [10]);

    # Run on a different connection
    my $result = await $script->run_on($other_redis, ['mykey'], [10]);

    # Legacy: call_with_keys (positional)
    my $result = await $script->call_with_keys(1, 'mykey', 10);

    # Legacy: call (assumes no KEYS, all ARGV)
    my $result = await $script->call('arg1', 'arg2');

=head1 DESCRIPTION

Script objects wrap Lua scripts for efficient reuse. They provide:

=over 4

=item * SHA1 hash computation and caching

=item * Automatic EVALSHA with EVAL fallback on NOSCRIPT

=item * Key prefixing support (via KeyExtractor)

=item * Metadata for named command registration

=back

=head1 CONSTRUCTOR

=head2 new

    my $script = Async::Redis::Script->new(
        redis       => $redis,          # Optional: default connection
        script      => $lua_code,       # Required: Lua source
        name        => 'my_command',    # Optional: for registry
        num_keys    => 1,               # Optional: fixed key count or 'dynamic'
        description => 'Does X',        # Optional: documentation
    );

Typically created via C<< $redis->script($lua) >> or C<< $redis->define_command() >>.

=head1 METHODS

=head2 run

    my $result = await $script->run(\@keys, \@args);

Preferred entry point. Executes the script with explicit keys and args arrays.
Uses EVALSHA with automatic EVAL fallback.

=head2 run_on

    my $result = await $script->run_on($redis, \@keys, \@args);

Execute on a specific Redis connection. Useful for:

=over 4

=item * Running in pipelines

=item * Using with connection pools

=item * Scripts created without a default connection

=back

=head2 call

    my $result = await $script->call(@args);

Legacy method. Assumes all arguments are ARGV (no KEYS).
Equivalent to C<< $script->run([], \@args) >>.

=head2 call_with_keys

    my $result = await $script->call_with_keys($numkeys, @keys_and_args);

Legacy method. First C<$numkeys> arguments are KEYS, rest are ARGV.

=head1 ACCESSORS

=head2 sha

    my $sha1 = $script->sha;

Returns the SHA1 hex digest of the script (lowercase).

=head2 script

    my $lua = $script->script;

Returns the Lua source code.

=head2 name

    my $name = $script->name;

Returns the command name (if registered via define_command).

=head2 num_keys

    my $n = $script->num_keys;

Returns the expected number of keys, or 'dynamic' if variable.

=head2 description

    my $desc = $script->description;

Returns the description string (if provided).

=head1 EVALSHA OPTIMIZATION

Scripts automatically use EVALSHA for efficiency. If the script isn't
cached on the Redis server (NOSCRIPT error), it falls back to EVAL
which also loads the script for future calls.

This is transparent - you don't need to manually load scripts.

=head1 SEE ALSO

L<Async::Redis> - Main client with C<script()> and C<define_command()> methods

=cut

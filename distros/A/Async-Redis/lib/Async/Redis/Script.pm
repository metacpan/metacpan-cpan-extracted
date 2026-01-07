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
        redis  => $args{redis},
        script => $script,
        sha    => lc(sha1_hex($script)),
        loaded => 0,
    }, $class;
}

sub sha    { shift->{sha} }
sub script { shift->{script} }

# Call with automatic key count detection
# Usage: $script->call('arg1', 'arg2')
# Assumes all args are ARGV (no KEYS)
# For explicit control, use call_with_keys()
async sub call {
    my ($self, @args) = @_;

    # Simple: assume all args are ARGV (no KEYS)
    # User should use call_with_keys for scripts with KEYS
    return await $self->call_with_keys(0, @args);
}

# Call with explicit key count
# Usage: $script->call_with_keys($numkeys, @keys, @args)
async sub call_with_keys {
    my ($self, $numkeys, @keys_and_args) = @_;

    my $redis = $self->{redis};

    # Note: Key prefixing is handled by KeyExtractor in command()
    # Don't apply it here to avoid double-prefixing

    # Use evalsha_or_eval for automatic fallback
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

Async::Redis::Script - Reusable Lua script wrapper

=head1 SYNOPSIS

    my $script = $redis->script(<<'LUA');
        local current = redis.call('GET', KEYS[1]) or 0
        return current + ARGV[1]
    LUA

    # Call with keys and args
    my $result = await $script->call_with_keys(1, 'mykey', 10);

    # Or simple call (assumes no KEYS, all ARGV)
    my $result = await $script->call('arg1', 'arg2');

=head1 DESCRIPTION

Script objects wrap Lua scripts for reuse. They:

- Compute and cache the SHA1 hash
- Use EVALSHA for efficiency
- Automatically fall back to EVAL on NOSCRIPT
- Apply key prefixing for KEYS arguments

=cut

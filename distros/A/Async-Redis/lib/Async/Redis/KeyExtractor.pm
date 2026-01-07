# lib/Future/IO/Redis/KeyExtractor.pm
package Async::Redis::KeyExtractor;

use strict;
use warnings;
use 5.018;

# Key position handlers for each command
# Generated from commands.json key_specs + manual overrides
our %KEY_POSITIONS = (
    # Simple single-key commands (first arg is key)
    'GET'       => sub { (0) },
    'SET'       => sub { (0) },
    'GETEX'     => sub { (0) },
    'GETDEL'    => sub { (0) },
    'GETSET'    => sub { (0) },
    'APPEND'    => sub { (0) },
    'STRLEN'    => sub { (0) },
    'SETEX'     => sub { (0) },
    'PSETEX'    => sub { (0) },
    'SETNX'     => sub { (0) },
    'SETRANGE'  => sub { (0) },
    'GETRANGE'  => sub { (0) },
    'INCR'      => sub { (0) },
    'DECR'      => sub { (0) },
    'INCRBY'    => sub { (0) },
    'DECRBY'    => sub { (0) },
    'INCRBYFLOAT' => sub { (0) },

    # Multi-key commands (all args are keys)
    'MGET'      => sub { (0 .. $#_) },
    'DEL'       => sub { (0 .. $#_) },
    'UNLINK'    => sub { (0 .. $#_) },
    'EXISTS'    => sub { (0 .. $#_) },
    'TOUCH'     => sub { (0 .. $#_) },
    'WATCH'     => sub { (0 .. $#_) },

    # MSET: even indices are keys
    'MSET'      => sub { grep { $_ % 2 == 0 } (0 .. $#_) },
    'MSETNX'    => sub { grep { $_ % 2 == 0 } (0 .. $#_) },

    # Hash commands (first arg is key)
    'HSET'      => sub { (0) },
    'HGET'      => sub { (0) },
    'HDEL'      => sub { (0) },
    'HEXISTS'   => sub { (0) },
    'HLEN'      => sub { (0) },
    'HKEYS'     => sub { (0) },
    'HVALS'     => sub { (0) },
    'HGETALL'   => sub { (0) },
    'HMSET'     => sub { (0) },
    'HMGET'     => sub { (0) },
    'HSETNX'    => sub { (0) },
    'HINCRBY'   => sub { (0) },
    'HINCRBYFLOAT' => sub { (0) },
    'HSCAN'     => sub { (0) },
    'HRANDFIELD' => sub { (0) },

    # List commands (first arg is key)
    'LPUSH'     => sub { (0) },
    'RPUSH'     => sub { (0) },
    'LPOP'      => sub { (0) },
    'RPOP'      => sub { (0) },
    'LLEN'      => sub { (0) },
    'LRANGE'    => sub { (0) },
    'LINDEX'    => sub { (0) },
    'LSET'      => sub { (0) },
    'LREM'      => sub { (0) },
    'LINSERT'   => sub { (0) },
    'LTRIM'     => sub { (0) },
    'LPOS'      => sub { (0) },
    'LPUSHX'    => sub { (0) },
    'RPUSHX'    => sub { (0) },

    # Blocking list commands (first arg is key, or multiple keys)
    'BLPOP'     => \&_keys_for_blocking_list,
    'BRPOP'     => \&_keys_for_blocking_list,
    'BLMOVE'    => sub { (0, 1) },  # source and dest
    'BRPOPLPUSH' => sub { (0, 1) },
    'LMOVE'     => sub { (0, 1) },

    # Set commands (first arg is key)
    'SADD'      => sub { (0) },
    'SREM'      => sub { (0) },
    'SMEMBERS'  => sub { (0) },
    'SISMEMBER' => sub { (0) },
    'SMISMEMBER' => sub { (0) },
    'SCARD'     => sub { (0) },
    'SPOP'      => sub { (0) },
    'SRANDMEMBER' => sub { (0) },
    'SSCAN'     => sub { (0) },
    'SMOVE'     => sub { (0, 1) },  # source and dest
    'SINTER'    => sub { (0 .. $#_) },
    'SUNION'    => sub { (0 .. $#_) },
    'SDIFF'     => sub { (0 .. $#_) },
    'SINTERSTORE' => sub { (0 .. $#_) },
    'SUNIONSTORE' => sub { (0 .. $#_) },
    'SDIFFSTORE' => sub { (0 .. $#_) },
    'SINTERCARD' => \&_keys_for_sintercard,

    # Sorted set commands (first arg is key)
    'ZADD'      => sub { (0) },
    'ZREM'      => sub { (0) },
    'ZSCORE'    => sub { (0) },
    'ZRANK'     => sub { (0) },
    'ZREVRANK'  => sub { (0) },
    'ZRANGE'    => sub { (0) },
    'ZREVRANGE' => sub { (0) },
    'ZRANGEBYSCORE' => sub { (0) },
    'ZREVRANGEBYSCORE' => sub { (0) },
    'ZCARD'     => sub { (0) },
    'ZCOUNT'    => sub { (0) },
    'ZINCRBY'   => sub { (0) },
    'ZLEXCOUNT' => sub { (0) },
    'ZRANGEBYLEX' => sub { (0) },
    'ZREVRANGEBYLEX' => sub { (0) },
    'ZPOPMIN'   => sub { (0) },
    'ZPOPMAX'   => sub { (0) },
    'BZPOPMIN'  => \&_keys_for_blocking_list,
    'BZPOPMAX'  => \&_keys_for_blocking_list,
    'ZRANGESTORE' => sub { (0, 1) },
    'ZINTER'    => \&_keys_for_zinter,
    'ZUNION'    => \&_keys_for_zinter,
    'ZDIFF'     => \&_keys_for_zinter,
    'ZINTERSTORE' => \&_keys_for_zinterstore,
    'ZUNIONSTORE' => \&_keys_for_zinterstore,
    'ZDIFFSTORE' => \&_keys_for_zinterstore,
    'ZSCAN'     => sub { (0) },
    'ZRANDMEMBER' => sub { (0) },
    'ZMPOP'     => \&_keys_for_zmpop,
    'BZMPOP'    => \&_keys_for_bzmpop,

    # Key commands
    'EXPIRE'    => sub { (0) },
    'EXPIREAT'  => sub { (0) },
    'PEXPIRE'   => sub { (0) },
    'PEXPIREAT' => sub { (0) },
    'TTL'       => sub { (0) },
    'PTTL'      => sub { (0) },
    'PERSIST'   => sub { (0) },
    'TYPE'      => sub { (0) },
    'RENAME'    => sub { (0, 1) },
    'RENAMENX'  => sub { (0, 1) },
    'COPY'      => sub { (0, 1) },
    'DUMP'      => sub { (0) },
    'RESTORE'   => sub { (0) },
    'EXPIRETIME' => sub { (0) },
    'PEXPIRETIME' => sub { (0) },
    'OBJECT'    => \&_keys_for_object,

    # EVAL/EVALSHA - dynamic based on numkeys
    'EVAL'      => \&_keys_for_eval,
    'EVALSHA'   => \&_keys_for_eval,
    'EVALSHA_RO' => \&_keys_for_eval,
    'EVAL_RO'   => \&_keys_for_eval,
    'FCALL'     => \&_keys_for_eval,
    'FCALL_RO'  => \&_keys_for_eval,

    # BITOP - skip operation arg
    'BITOP'     => sub { (1 .. $#_) },

    # Stream commands
    'XADD'      => sub { (0) },
    'XLEN'      => sub { (0) },
    'XRANGE'    => sub { (0) },
    'XREVRANGE' => sub { (0) },
    'XREAD'     => \&_keys_for_xread,
    'XREADGROUP' => \&_keys_for_xread,
    'XINFO'     => \&_keys_for_xinfo,
    'XGROUP'    => \&_keys_for_xgroup,
    'XACK'      => sub { (0) },
    'XCLAIM'    => sub { (0) },
    'XAUTOCLAIM' => sub { (0) },
    'XPENDING'  => sub { (0) },
    'XTRIM'     => sub { (0) },
    'XDEL'      => sub { (0) },
    'XSETID'    => sub { (0) },

    # Geo commands
    'GEOADD'    => sub { (0) },
    'GEOPOS'    => sub { (0) },
    'GEODIST'   => sub { (0) },
    'GEOHASH'   => sub { (0) },
    'GEORADIUS' => \&_keys_for_georadius,
    'GEORADIUSBYMEMBER' => \&_keys_for_georadius,
    'GEOSEARCH' => sub { (0) },
    'GEOSEARCHSTORE' => sub { (0, 1) },

    # MIGRATE - special handling
    'MIGRATE'   => \&_keys_for_migrate,

    # SORT
    'SORT'      => sub { (0) },
    'SORT_RO'   => sub { (0) },

    # SCAN commands return patterns, not keys - first arg is key for HSCAN/SSCAN/ZSCAN
    'SCAN'      => sub { () },  # No key, cursor-based

    # Pub/Sub - channels, not keys
    'PUBLISH'   => sub { () },
    'SUBSCRIBE' => sub { () },
    'UNSUBSCRIBE' => sub { () },
    'PSUBSCRIBE' => sub { () },
    'PUNSUBSCRIBE' => sub { () },

    # Server commands - no keys
    'PING'      => sub { () },
    'ECHO'      => sub { () },
    'AUTH'      => sub { () },
    'SELECT'    => sub { () },
    'INFO'      => sub { () },
    'DBSIZE'    => sub { () },
    'FLUSHDB'   => sub { () },
    'FLUSHALL'  => sub { () },
    'SAVE'      => sub { () },
    'BGSAVE'    => sub { () },
    'LASTSAVE'  => sub { () },
    'TIME'      => sub { () },
    'CONFIG'    => sub { () },
    'CLIENT'    => sub { () },
    'SLOWLOG'   => sub { () },
    'DEBUG'     => sub { () },
    'MEMORY'    => sub { () },
    'MODULE'    => sub { () },
    'ACL'       => sub { () },
    'COMMAND'   => sub { () },
    'MULTI'     => sub { () },
    'EXEC'      => sub { () },
    'DISCARD'   => sub { () },
    'UNWATCH'   => sub { () },
    'SCRIPT'    => sub { () },
    'CLUSTER'   => sub { () },
    'READONLY'  => sub { () },
    'READWRITE' => sub { () },
    'WAIT'      => sub { () },
    'KEYS'      => sub { () },  # Pattern, not literal key
    'RANDOMKEY' => sub { () },
);

# Fallback patterns for unknown commands
our @FALLBACK_PATTERNS = (
    # Hash commands: first arg is key
    [ qr/^H(?:SET|GET|DEL|EXISTS|INCR|LEN|KEYS|VALS|GETALL|SCAN|MGET|MSET)/i, sub { (0) } ],

    # List commands: first arg is key
    [ qr/^[LR](?:PUSH|POP|LEN|INDEX|RANGE|SET|TRIM|REM|INSERT|POS)/i, sub { (0) } ],

    # Set commands: first arg is key
    [ qr/^S(?:ADD|REM|MEMBERS|ISMEMBER|CARD|POP|RANDMEMBER|SCAN)/i, sub { (0) } ],

    # Sorted set commands: first arg is key
    [ qr/^Z(?:ADD|REM|SCORE|RANK|RANGE|CARD|COUNT|INCRBY|SCAN)/i, sub { (0) } ],

    # Generic fallback: assume first arg is key for unknown X* commands (streams)
    [ qr/^X/i, sub { (0) } ],
);

sub extract_key_indices {
    my ($command, @args) = @_;
    $command = uc($command);

    # Check explicit handlers
    if (my $handler = $KEY_POSITIONS{$command}) {
        return $handler->(@args);
    }

    # Try fallback patterns
    for my $pattern (@FALLBACK_PATTERNS) {
        if ($command =~ $pattern->[0]) {
            return $pattern->[1]->(@args);
        }
    }

    # Unknown command - no prefixing, warn in debug mode
    warn "Unknown command '$command': key prefixing skipped" if $ENV{REDIS_DEBUG};
    return ();
}

sub apply_prefix {
    my ($prefix, $command, @args) = @_;
    return @args unless defined $prefix && $prefix ne '';

    my @key_indices = extract_key_indices($command, @args);
    for my $i (@key_indices) {
        next if $i > $#args;  # Safety check
        $args[$i] = $prefix . $args[$i];
    }

    return @args;
}

# --- Custom handlers for complex commands ---

sub _keys_for_eval {
    my (@args) = @_;
    # EVAL script numkeys [key ...] [arg ...]
    # EVALSHA sha1 numkeys [key ...] [arg ...]
    return () unless @args >= 2;

    my $numkeys = $args[1];
    return () unless defined $numkeys && $numkeys =~ /^\d+$/ && $numkeys > 0;

    # Keys are at indices 2 through 2+numkeys-1
    return (2 .. 2 + $numkeys - 1);
}

sub _keys_for_xread {
    my (@args) = @_;

    # Find STREAMS keyword
    my $streams_idx;
    for my $i (0 .. $#args) {
        if (uc($args[$i]) eq 'STREAMS') {
            $streams_idx = $i;
            last;
        }
    }
    return () unless defined $streams_idx;

    # Keys are between STREAMS and the IDs
    # Number of streams = number of IDs = (remaining args after STREAMS) / 2
    my $remaining = $#args - $streams_idx;
    my $num_streams = int($remaining / 2);

    return () unless $num_streams > 0;
    return ($streams_idx + 1 .. $streams_idx + $num_streams);
}

sub _keys_for_migrate {
    my (@args) = @_;
    my @key_indices;

    # MIGRATE host port key|"" db timeout [COPY] [REPLACE] [AUTH pw] [KEYS k1 k2 ...]

    # Single key at position 2 (unless empty string for multi-key)
    if (@args > 2 && $args[2] ne '') {
        push @key_indices, 2;
    }

    # Multi-key after KEYS keyword
    for my $i (0 .. $#args) {
        if (uc($args[$i]) eq 'KEYS') {
            push @key_indices, ($i + 1 .. $#args);
            last;
        }
    }

    return @key_indices;
}

sub _keys_for_object {
    my (@args) = @_;
    # OBJECT subcommand [key] [...]
    return () unless @args >= 2;

    my $subcmd = uc($args[0]);
    # Most OBJECT subcommands take key as second arg
    if ($subcmd =~ /^(ENCODING|FREQ|IDLETIME|REFCOUNT)$/) {
        return (1);
    }
    return ();
}

sub _keys_for_blocking_list {
    my (@args) = @_;
    # BLPOP key [key ...] timeout
    # Last arg is timeout, rest are keys
    return () unless @args >= 2;
    return (0 .. $#args - 1);
}

sub _keys_for_zinter {
    my (@args) = @_;
    # ZINTER numkeys key [key ...] [WEIGHTS ...] [AGGREGATE ...]
    return () unless @args >= 1;
    my $numkeys = $args[0];
    return () unless $numkeys =~ /^\d+$/ && $numkeys > 0;
    return (1 .. $numkeys);
}

sub _keys_for_zinterstore {
    my (@args) = @_;
    # ZINTERSTORE destination numkeys key [key ...] [WEIGHTS ...] [AGGREGATE ...]
    return () unless @args >= 2;
    my $numkeys = $args[1];
    return () unless $numkeys =~ /^\d+$/ && $numkeys > 0;
    return (0, 2 .. 1 + $numkeys);  # dest + source keys
}

sub _keys_for_sintercard {
    my (@args) = @_;
    # SINTERCARD numkeys key [key ...] [LIMIT limit]
    return () unless @args >= 1;
    my $numkeys = $args[0];
    return () unless $numkeys =~ /^\d+$/ && $numkeys > 0;
    return (1 .. $numkeys);
}

sub _keys_for_zmpop {
    my (@args) = @_;
    # ZMPOP numkeys key [key ...] MIN|MAX [COUNT count]
    return () unless @args >= 1;
    my $numkeys = $args[0];
    return () unless $numkeys =~ /^\d+$/ && $numkeys > 0;
    return (1 .. $numkeys);
}

sub _keys_for_bzmpop {
    my (@args) = @_;
    # BZMPOP timeout numkeys key [key ...] MIN|MAX [COUNT count]
    return () unless @args >= 2;
    my $numkeys = $args[1];
    return () unless $numkeys =~ /^\d+$/ && $numkeys > 0;
    return (2 .. 1 + $numkeys);
}

sub _keys_for_xinfo {
    my (@args) = @_;
    # XINFO STREAM key, XINFO GROUPS key, etc.
    return () unless @args >= 2;
    my $subcmd = uc($args[0]);
    if ($subcmd =~ /^(STREAM|GROUPS|CONSUMERS)$/) {
        return (1);
    }
    return ();
}

sub _keys_for_xgroup {
    my (@args) = @_;
    # XGROUP CREATE key groupname id, XGROUP DESTROY key groupname, etc.
    return () unless @args >= 2;
    my $subcmd = uc($args[0]);
    if ($subcmd =~ /^(CREATE|DESTROY|SETID|DELCONSUMER|CREATECONSUMER)$/) {
        return (1);
    }
    return ();
}

sub _keys_for_georadius {
    my (@args) = @_;
    my @indices = (0);  # First arg is always key

    # Look for STORE and STOREDIST
    for my $i (0 .. $#args - 1) {
        if (uc($args[$i]) =~ /^(STORE|STOREDIST)$/) {
            push @indices, $i + 1;
        }
    }

    return @indices;
}

1;

__END__

=head1 NAME

Async::Redis::KeyExtractor - Key position detection for Redis commands

=head1 SYNOPSIS

    use Async::Redis::KeyExtractor;

    # Get indices of key arguments
    my @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'MSET', 'k1', 'v1', 'k2', 'v2'
    );
    # @indices = (0, 2)

    # Apply prefix to keys only
    my @args = Async::Redis::KeyExtractor::apply_prefix(
        'myapp:', 'MSET', 'k1', 'v1', 'k2', 'v2'
    );
    # @args = ('myapp:k1', 'v1', 'myapp:k2', 'v2')

=head1 DESCRIPTION

This module handles the complex task of identifying which arguments to Redis
commands are keys (and should receive namespace prefixes) vs values/options
(which should not be modified).

=cut

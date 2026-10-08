use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec ();
use POSIX ();

# The ten xs/*.xs files carry near-duplicate copies of every guard; each row
# names its variant so a lost copy fails exactly that row.  Regexes are anchored
# at the start of $@: croak appends " at FILE line N.", which an unanchored
# pattern naming a word from this file's name would match.

my $dir = tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, "$_[0].shm") }

# Guards whose absence crashes or corrupts run in a child, so a regression fails
# one row; the child reports by exit status and leaves via _exit, running no END
# block.
sub in_child {
    my ($code) = @_;
    my $pid = fork // die "fork: $!";
    POSIX::_exit($code->()) unless $pid;
    waitpid $pid, 0;
    return $?;
}

#  variant, a key of its key type, a value of its value type, has counters
my @VARIANTS = (
    [ 'I16',  1,   2,   1 ],
    [ 'I16S', 1,   'v', 0 ],
    [ 'I32',  1,   2,   1 ],
    [ 'I32S', 1,   'v', 0 ],
    [ 'II',   1,   2,   1 ],
    [ 'IS',   1,   'v', 0 ],
    [ 'SI',   'k', 2,   1 ],
    [ 'SI16', 'k', 2,   1 ],
    [ 'SI32', 'k', 2,   1 ],
    [ 'SS',   'k', 'v', 0 ],
);
for (@VARIANTS) {
    my $class = "Data::HashMap::Shared::$_->[0]";
    eval "require $class; 1" or die $@;
}

{
    my $re = qr/^Data::HashMap::Shared::\w+: operation requires a TTL-enabled map \(pass ttl > 0 to constructor\)/;
    for my $v (@VARIANTS) {
        my ($name, $key, $val) = @$v;
        my $m = "Data::HashMap::Shared::$name"->new(path("ttl_$name"), 64);
        for my $op (qw(put_ttl add_ttl update_ttl)) {
            eval { $m->$op($key, $val, 5); 1 };
            like $@, $re, "$name: $op on a map with no TTL croaks";
        }
    }
}

{
    for my $v (@VARIANTS) {
        my $class = "Data::HashMap::Shared::$v->[0]";
        eval { $class->new_readonly(undef); 1 };
        like $@, qr/^\Q$class\E->new_readonly: path is required/,
            "$v->[0]: new_readonly(undef) croaks, naming the class";
    }
}

{
    my $re = qr/^Data::HashMap::Shared::\w+: set_multi requires an even number of arguments \(key, value pairs\)/;
    for my $v (@VARIANTS) {
        my ($name, $key) = @$v;
        my $m = "Data::HashMap::Shared::$name"->new(path("sm_$name"), 64);
        eval { $m->set_multi($key); 1 };
        like $@, $re, "$name: set_multi with one argument croaks";
    }
}

# incr/decr/incr_by/max/min die rather than return false when a new key has no
# room
{
    for my $v (grep { $_->[3] } @VARIANTS) {
        my ($name, $key) = @$v;
        my $strkey = $name =~ /^S/;
        my $m = "Data::HashMap::Shared::$name"->new(path("full_$name"), 2);   # the 16-slot floor
        my $n = 0;
        $n++ while $n < 10_000 && $m->put($strkey ? "k$n" : $n, 1);
        ok $n > 0 && $n < 10_000, "$name: map filled to capacity at $n entries";

        my $i = 0;
        for my $op ([ incr    => 'increment', [] ],
                    [ decr    => 'decrement', [] ],
                    [ incr_by => 'incr_by',   [5] ],
                    [ max     => 'max',       [5] ],
                    [ min     => 'min',       [5] ]) {
            my ($method, $word, $extra) = @$op;
            my $fresh = $strkey ? "absent$i" : 20_000 + $i;   # fits int16
            $i++;
            eval { $m->$method($fresh, @$extra); 1 };
            like $@, qr/^\QData::HashMap::Shared::$name: $word failed\E/,
                "$name: $method on a new key croaks when the table is full";
        }
    }
}

{
    for my $v (@VARIANTS) {
        my $name  = $v->[0];
        my $class = "Data::HashMap::Shared::$name";
        my $st = in_child(sub {
            my $m = $class->new(path("ud_$name"), 16);
            $m->DESTROY;
            return 20 if eval { $m->unlink; 1 };
            return $@ =~ /^\QAttempted to use a destroyed $class object\E/ ? 0 : 21;
        });
        is $st, 0, "$name: unlink on an explicitly destroyed handle croaks"
            or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
    }
}

{
    for my $v (@VARIANTS) {
        my $class = "Data::HashMap::Shared::$v->[0]";
        my $usage = "Usage: $class->unlink(\$path)";
        my $st = in_child(sub {
            eval { $class->unlink(); 1 } and return 20;
            return $@ =~ /^\Q$usage\E/ ? 0 : 21;
        });
        is $st, 0, "$v->[0]: class-form unlink with no path croaks"
            or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
    }
}

# DESTROY on another variant's object (t/45 does not cover it): without the
# class test the victim is closed or freed from under its owner; no crash (the
# IV is zeroed first, so the next call croaks), so the oracle is that the victim
# still works.
{
    for my $v (@VARIANTS) {
        my $name = $v->[0];
        my ($wname, $wkey, $wval) = @{ $VARIANTS[ $VARIANTS[0][0] eq $name ? 1 : 0 ] };
        my $st = in_child(sub {
            my $w = "Data::HashMap::Shared::$wname"->new(path("fdm_$name"), 64);
            $w->put($wkey, $wval);
            my $d = do { no strict 'refs'; \&{"Data::HashMap::Shared::${name}::DESTROY"} };
            return 22 unless eval { $d->($w); 1 };
            return (eval { $w->size } // -1) == 1 ? 0 : 20;
        });
        is $st, 0, "$name: DESTROY on a $wname map leaves that map alive"
            or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
    }
    for my $v (@VARIANTS) {
        my $name = $v->[0];
        my ($wname, $wkey, $wval) = @{ $VARIANTS[ $VARIANTS[0][0] eq $name ? 1 : 0 ] };
        my $st = in_child(sub {
            my $w = "Data::HashMap::Shared::$wname"->new(path("fdc_$name"), 64);
            $w->put($wkey, $wval);
            my $c = $w->cursor;
            my $d = do { no strict 'refs'; \&{"Data::HashMap::Shared::${name}::Cursor::DESTROY"} };
            return 22 unless eval { $d->($c); 1 };
            my @kv = eval { $c->next };
            return @kv == 2 && $kv[0] eq $wkey ? 0 : 20;
        });
        is $st, 0, "$name: Cursor::DESTROY on a $wname cursor leaves that cursor alive"
            or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
    }
    # a guard drifted to a sibling's class name would still reject the foreign
    # cursor above
    for my $v (@VARIANTS) {
        my ($name, $key, $val) = @$v;
        my $st = in_child(sub {
            my $m = "Data::HashMap::Shared::$name"->new(path("odc_$name"), 64);
            $m->put($key, $val);
            my $c = $m->cursor;
            $c->DESTROY;
            eval { $c->next; 1 } and return 20;
            return $@ =~ /^Attempted to use a destroyed \S+ cursor/ ? 0 : 21;
        });
        is $st, 0, "$name: Cursor::DESTROY on its own cursor frees it"
            or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
    }
}

# Constructor sizes are range-checked, not truncated: new($p, 2**32 + 100) would
# build a 100-entry map.  Every copy croaks before allocating, so no row creates
# a file, shards or a memfd.
{
    my $N = 2**32;
    for my $v (@VARIANTS) {
        my $name  = $v->[0];
        my $class = "Data::HashMap::Shared::$name";
        my $pfx   = path("u32_$name");
        #  constructor,  argument,      an argument list with 2**32 in that position
        for my $c ([ new         => max_entries => [ undef, $N ] ],
                   [ new         => lru_max     => [ undef, 64, $N ] ],
                   [ new         => ttl_default => [ undef, 64, 0, $N ] ],
                   [ new         => lru_skip    => [ undef, 64, 0, 0, $N ] ],
                   [ new_sharded => max_entries => [ $pfx, 2, $N ] ],
                   [ new_sharded => lru_max     => [ $pfx, 2, 64, $N ] ],
                   [ new_sharded => ttl_default => [ $pfx, 2, 64, 0, $N ] ],
                   [ new_sharded => lru_skip    => [ $pfx, 2, 64, 0, 0, $N ] ],
                   [ new_sharded => num_shards  => [ $pfx, $N, 64 ] ],
                   [ new_memfd   => max_entries => [ "u32_$name", $N ] ],
                   [ new_memfd   => lru_max     => [ "u32_$name", 64, $N ] ],
                   [ new_memfd   => ttl_default => [ "u32_$name", 64, 0, $N ] ],
                   [ new_memfd   => lru_skip    => [ "u32_$name", 64, 0, 0, $N ] ]) {
            my ($ctor, $what, $args) = @$c;
            eval { $class->$ctor(@$args); 1 };
            like $@,
                qr/^\Q$class: $what 4294967296 exceeds the maximum of 4294967295\E/,
                "$name: $ctor rejects a $what of 2**32";
        }
    }
}

# Per-call uint32 arguments; a lost copy turns a 2**32-second TTL into 0,
# silently clearing a live one.
{
    my $N = 2**32;
    for my $v (@VARIANTS) {
        my ($name, $key, $val) = @$v;
        my $m = "Data::HashMap::Shared::$name"->new(path("u32c_$name"), 64, 0, 60);
        $m->put($key, $val);
        for my $c ([ set_ttl               => ttl    => [ $key, $N ] ],
                   [ put_ttl               => ttl    => [ $key, $val, $N ] ],
                   [ add_ttl               => ttl    => [ $key, $val, $N ] ],
                   [ update_ttl            => ttl    => [ $key, $val, $N ] ],
                   [ flush_expired_partial => limit  => [ $N ] ],
                   [ reserve               => target => [ $N ] ]) {
            my ($meth, $what, $args) = @$c;
            eval { $m->$meth(@$args); 1 };
            like $@,
                qr/^\QData::HashMap::Shared::$name: $what 4294967296 exceeds the maximum of 4294967295\E/,
                "$name: $meth rejects a $what of 2**32";
        }
    }
}

done_testing;

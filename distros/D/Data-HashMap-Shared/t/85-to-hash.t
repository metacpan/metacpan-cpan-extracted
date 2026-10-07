use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp qw(tempdir);

# to_hash, keys, values and items copy the entries under the read lock and build
# their result afterwards.  It must be the live entries: every variant, plain
# and sharded, with empty, binary, Latin-1 and UTF-8 strings, and without an
# expired entry.

my $dir = tempdir(CLEANUP => 1);
my %shape = (II => 'ii', I16 => 'ii', I32 => 'ii', IS => 'is', I16S => 'is', I32S => 'is',
             SI => 'si', SI16 => 'si', SI32 => 'si', SS => 'ss');
my @skeys = ('', "a\0b", "\xe9", "\x{263a}", map "key$_", 1 .. 40);
my @ikeys = (-20 .. 23);

my @cases;
for my $v (sort keys %shape) {
    my $class = "Data::HashMap::Shared::$v";
    eval "require $class; 1" or die $@;
    my ($ks, $vs) = split //, $shape{$v};
    my @keys = $ks eq 's' ? @skeys : @ikeys;
    for my $shards (0, 3) {
        my $m = $shards ? $class->new_sharded("$dir/$v", $shards, 1000, 0, 60)
                        : $class->new(undef, 1000, 0, 60);
        my %expect;
        for my $i (0 .. $#keys) {
            my $val = $vs eq 's' ? ($i % 3 == 0 ? "v\x{2603}$i" : $i % 3 == 1 ? "v\0$i" : '') : $i * 7;
            $m->put($keys[$i], $val);
            $expect{ $keys[$i] } = $val;
        }
        $m->put_ttl($ks eq 's' ? 'gone' : 99, $vs eq 's' ? 'x' : 1, 1);
        push @cases, [ $v . ($shards ? " ($shards shards)" : ''), $m, \%expect ];
    }
}

Time::HiRes::sleep(2.1);

my $flags = sub { my $h = shift; +{ map { $_ => utf8::is_utf8($_) ? 1 : 0 } keys %$h } };
my $utf8 = sub { join '', map { utf8::is_utf8($_) ? 1 : 0 } @_ };
for (@cases) {
    my ($name, $m, $expect) = @$_;
    my $h = $m->to_hash;
    is_deeply $h, $expect, "$name: to_hash holds every live entry and no expired one";
    is_deeply $flags->($h), $flags->($expect), "$name: ... with each key's UTF-8 flag";

    my @kv = $m->items;
    my @k = $m->keys;
    my @v = $m->values;
    is_deeply { @kv }, $expect, "$name: items holds them too";
    is scalar(@kv), 2 * keys %$expect, "$name: ... each once";
    is_deeply [ map { ($k[$_], $v[$_]) } 0 .. $#k ], \@kv, "$name: ... as keys and values do, in the same order";
    is $utf8->(@kv), $utf8->(map { ($_, $expect->{$_}) } @k),
        "$name: ... with each key's and value's UTF-8 flag";
}

for my $v (sort keys %shape) {
    my $m = "Data::HashMap::Shared::$v"->new(undef, 100);
    is_deeply [ $m->keys, $m->values, $m->items ], [], "$v: an empty map lists nothing";
}

# From 4096 entries in a shard on, strings are copied out packed and made SVs
# once the lock is released.
for my $v (qw(IS SI SS)) {
    my ($ks, $vs) = split //, $shape{$v};
    for my $shards (0, 2) {
        my $class = "Data::HashMap::Shared::$v";
        my $m = $shards ? $class->new_sharded("$dir/big$v", $shards, 20_000) : $class->new(undef, 20_000);
        my %expect = map {
            ($ks eq 's' ? ($_ % 5 ? "key$_" : "k\x{263a}$_") : $_)
                => ($vs eq 's' ? ($_ % 7 ? "value$_" : $_ % 2 ? "v\x{2603}$_" : '') : $_ * 3)
        } 1 .. 10_000;
        $m->set_multi(%expect);
        my $name = "$v, 10000 entries" . ($shards ? " in $shards shards" : '');
        my @kv = $m->items;
        my @k = $m->keys;
        my @v = $m->values;
        is_deeply { @kv }, \%expect, "$name: items holds every entry";
        is scalar(@kv), 2 * keys %expect, "$name: ... each once";
        ok !grep({ $k[$_] ne $kv[2 * $_] || $v[$_] ne $kv[2 * $_ + 1] } 0 .. $#k) && @k == @v && 2 * @k == @kv,
            "$name: ... as keys and values do, in the same order";
        is $utf8->(@kv), $utf8->(map { ($_, $expect{$_}) } @k), "$name: ... with each UTF-8 flag";
        is_deeply $m->to_hash, \%expect, "$name: and to_hash";
    }
}

done_testing;

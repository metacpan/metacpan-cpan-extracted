use strict;
use warnings;
use File::Temp qw(tempdir);
use Test::More;

plan skip_all => 'author tests' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);

for my $variant (qw(II I16 I32 IS I16S I32S SI SI16 SI32 SS)) {
    my $pkg = "Data::HashMap::Shared::$variant";
    eval "require $pkg; 1" or die $@;
    my $strkey = $variant =~ /^S/;
    my $strval = $variant =~ /S$/;
    my $width = $variant =~ /16/ ? 's' : $variant =~ /32/ ? 'l' : 'q';
    my @keys = map { $strkey ? $_ == 0 ? '' : "key-$_" . ('k' x ($_ % 70)) : $_ - 64 } 0 .. 127;
    # without LRU or TTL, counters, cas and get_or_set take the read-lock paths
    for my $cfg ([0, 0, 3600], [1, 0, 3600], [0, 0, 0], [1, 0, 0], [0, 200, 0]) {
        my ($sharded, $max_size, $ttl) = @$cfg;
        srand(730 + $sharded);
        my $m = $sharded ? $pkg->new_sharded("$dir/$variant-$ttl", 4, 1000, $max_size, $ttl, 0, 1 << 20)
                         : $pkg->new(undef, 1000, $max_size, $ttl, 0, 1 << 20);
        my %want;
        my $value = sub {
            my $n = int(rand(180001)) - 90000;
            return unpack($width, pack($width, $n)) unless $strval;
            my $s = chr(65 + abs($n) % 26) x (abs($n) % 700);
            utf8::upgrade($s) if $n % 2;
            return $s;
        };
        my $expect = sub {
            my ($actual, $expected, $label) = @_;
            die "$variant/$sharded $label: value mismatch\n"
                unless defined($actual) == defined($expected)
                    && (!defined($actual) || $actual eq $expected);
            die "$variant/$sharded $label: UTF-8 flag mismatch\n"
                if $strval && defined($actual)
                    && !!utf8::is_utf8($actual) != !!utf8::is_utf8($expected);
        };
        for my $i (1 .. 10000) {
            my $k = $keys[int rand @keys];
            my $v = $value->();
            my $op = int rand 18;
            if ($op == 0) {
                die 'put refused' unless $m->put($k, $v);
                $want{$k} = $v;
            } elsif ($op == 1) {
                my $present = exists $want{$k};
                $expect->(0 + $m->add($k, $v), $present ? 0 : 1, 'add');
                $want{$k} = $v unless $present;
            } elsif ($op == 2) {
                my $present = exists $want{$k};
                $expect->(0 + $m->update($k, $v), $present ? 1 : 0, 'update');
                $want{$k} = $v if $present;
            } elsif ($op == 3) {
                $expect->($m->swap($k, $v), $want{$k}, 'swap');
                $want{$k} = $v;
            } elsif ($op == 4) {
                $want{$k} = $v unless exists $want{$k};
                $expect->($m->get_or_set($k, $v), $want{$k}, 'get_or_set');
            } elsif ($op == 5) {
                $expect->(0 + $m->remove($k), exists($want{$k}) ? 1 : 0, 'remove');
                delete $want{$k};
            } elsif ($op == 6) {
                $expect->($m->take($k), delete($want{$k}), 'take');
            } elsif ($op == 7 || $op == 8) {
                my $expected = rand() < .6 && exists($want{$k}) ? $want{$k} : $value->();
                my $match = exists($want{$k}) && $want{$k} eq $expected;
                if ($op == 7) {
                    $expect->(0 + $m->cas($k, $expected, $v), $match ? 1 : 0, 'cas');
                    $want{$k} = $v if $match;
                } else {
                    $expect->($m->cas_take($k, $expected), $match ? $want{$k} : undef, 'cas_take');
                    delete $want{$k} if $match;
                }
            } elsif ($op == 9) {
                my @pairs = map { ($keys[int rand @keys], $value->()) } 1 .. 5;
                $expect->($m->set_multi(@pairs), 5, 'set_multi');
                while (@pairs) {
                    my ($key, $val) = splice(@pairs, 0, 2);
                    $want{$key} = $val;
                }
            } elsif ($op == 10) {
                my @ks = map { $keys[int rand @keys] } 1 .. 5;
                my $n = 0;
                for (@ks) { $n++ if exists $want{$_}; delete $want{$_}; }
                $expect->($m->remove_multi(@ks), $n, 'remove_multi');
            } elsif ($op == 11) {
                my @ks = map { $keys[int rand @keys] } 1 .. 5;
                my @got = $m->get_multi(@ks);
                $expect->(scalar(@got), scalar(@ks), 'get_multi length');
                $expect->($got[$_], $want{$ks[$_]}, 'get_multi') for 0 .. $#ks;
            } elsif ($op >= 12 && $op <= 14) {
                my $n = keys %want;
                my @got = $op == 12 ? $m->pop : $op == 13 ? $m->shift : $m->drain(3);
                $n = 3 if $op == 14 && $n > 3;
                $n = 1 if $op != 14 && $n;
                $expect->(scalar(@got), 2 * $n, 'drained length');
                while (@got) {
                    my ($key, $val) = splice(@got, 0, 2);
                    die 'unknown drained key' unless exists $want{$key};
                    $expect->($val, delete($want{$key}), 'drained value');
                }
            } elsif ($op == 16 && !$strval) {
                $want{$k} = unpack($width, pack($width, ($want{$k} // 0) + $v));
                $expect->($m->incr_by($k, $v), $want{$k}, 'incr_by');
            } elsif ($op == 17 && !$strval) {
                my $max = rand() < .5;
                $want{$k} = $v if !exists($want{$k}) || ($max ? $v > $want{$k} : $v < $want{$k});
                $expect->($max ? $m->max($k, $v) : $m->min($k, $v), $want{$k}, 'min/max');
            } else {
                $m->compact;
            }
            if ($i % 200 == 0) {
                die "$variant/$sharded wrong size" unless $m->size == keys %want;
                my $got = $m->to_hash;
                die 'wrong snapshot size' unless keys(%$got) == keys(%want);
                for my $key (@keys) {
                    $expect->($m->get($key), $want{$key}, "get at $i");
                    $expect->($got->{$key}, $want{$key}, "snapshot at $i");
                }
                my $c = $m->cursor;
                my %seen;
                while (my ($key, $val) = $c->next) {
                    die 'duplicate cursor key' if exists $seen{$key};
                    $seen{$key} = $val;
                }
                die 'cursor count mismatch' unless keys(%seen) == keys(%want);
                $expect->($seen{$_}, $want{$_}, 'cursor value') for keys %want;
            }
        }
        pass "$variant " . ($sharded ? 'sharded' : 'single') . " max_size=$max_size ttl=$ttl: "
            . '10,000 mixed operations match an oracle';
    }
}
done_testing;

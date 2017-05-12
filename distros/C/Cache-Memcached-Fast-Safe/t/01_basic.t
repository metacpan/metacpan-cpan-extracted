use strict;
use warnings;
use utf8;
use Test::More;

use Test::TCP qw/empty_port wait_port/;
use Test::Skip::UnlessExistsExecutable;
use File::Which qw(which);
use Proc::Guard;
use Cache::Memcached::Fast::Safe;
use Encode;
#use Log::Minimal;
#$Log::Minimal::AUTODUMP =1;

skip_all_unless_exists 'memcached';

my @memcached;
my @user = ();
if ( $> == 0 ) {
    @user = ('-u','nobody');
}

for ( 1..5 ) {
    my $port = empty_port();
    my $proc = proc_guard( scalar which('memcached'), '-p', $port, '-U', 0, '-l', '127.0.0.1', @user );
    wait_port($port);
    push @memcached, { proc => $proc, port => $port };
}

my $cache = Cache::Memcached::Fast::Safe->new({
    servers => [map { "localhost:" . $_->{port} } @memcached],
    utf8 => 1,
});
my $version = $cache->server_versions;
my $version_num = 2 ** 31;
while (my ($s, $v) = each %$version) {
    if ($v =~ /(\d+)\.(\d+)\.(\d+)/) {
        my $n = $1 * 10000 + $2 * 100 + $3;
        if ($n < $version_num) {
            $version_num = $n;
        }
    }
}

use constant count => 100;

my @keys1 = ('c o m m a n d s あ', "あ"x100);

for my $key ( @keys1 ) {
    $cache->delete($key);
    ok($cache->add($key, 'v1', undef), 'Add');

    is($cache->get($key), 'v1', 'Fetch');
    ok($cache->set($key, 'v2', undef), 'Set');
    is($cache->get($key), 'v2', 'Fetch');
    ok($cache->replace($key, 'v3'), 'Replace');
    is($cache->get($key), 'v3', 'Fetch');

    ok($cache->replace($key, 0), 'replace with numeric');
    ok($cache->incr($key), 'Incr');
    ok($cache->get($key) == 1, 'Fetch');
    ok($cache->incr($key, 5), 'Incr');
    ok((not $cache->incr('no-such-key', 5)), 'Incr no_such_key');
    ok((defined $cache->incr('no-such-key', 5)),
       'Incr no_such_key returns defined value');
    ok($cache->get($key) == 6, 'Fetch');
    ok($cache->decr($key), 'Decr');
    ok($cache->get($key) == 5, 'Fetch');
    ok($cache->decr($key, 2), 'Decr');
    ok($cache->get($key) == 3, 'Fetch');
    ok($cache->decr($key, 100) == 0, 'Decr below zero');
    ok($cache->decr($key, 100), 'Decr below zero returns true value');
    ok($cache->get($key) == 0, 'Fetch');
}

ok($cache->get_multi(), 'get_multi() with empty list');

my $res = $cache->set_multi();
isa_ok($res, 'HASH');
is(scalar keys %$res, 0);
my @res = $cache->set_multi();
is(@res, 0);


my @keys = map { "c o m m a n d s あ - $_" } (1..count-1);
push @keys, "c o m m a n d s - 100"x100;
 
@res = $cache->set_multi(map { [$_, $_] } @keys);
is(@res, count);
is((grep { not $_ } @res), 0);

$res = $cache->set_multi(map { [$_, $_] } @keys);
isa_ok($res, 'HASH');
is(keys %$res, count);
is((grep { not $_ } values %$res), 0);


my @extra_keys = @keys;
for (1..count) {
    splice(@extra_keys, int(rand(@extra_keys + 1)), 0, "no_such_key-$_");
}
$res = $cache->get_multi(@extra_keys);

isa_ok($res, 'HASH');
is(scalar keys %$res, scalar @keys, 'Number of entries in result');
my $count = 0;
foreach my $k (@keys) {
    ++$count if exists $res->{$k} and $res->{$k} eq $k;
}
is($count, count);

SKIP: {
    skip "memcached 1.2.4 is required for cas/gets/append/prepend commands", 27
      if $version_num < 10204;
    my $key = $keys1[0];
    ok($cache->set($key, 'value'), 'Store');
    ok($cache->append($key, '-append'), 'Append');
    is($cache->get($key), 'value-append', 'Fetch');
    ok($cache->prepend($key, 'prepend-'), 'Prepend');
    is($cache->get($key), 'prepend-value-append', 'Fetch');

    $res = $cache->gets($key);
    ok($res, 'Gets');
    isa_ok($res, 'ARRAY');
    is(scalar @$res, 2, 'Gets result is an array of two elements');
    ok($res->[0], 'CAS opaque defined');
    is($res->[1], 'prepend-value-append', 'Match value');
    $res->[1] = 'new value';
    ok($cache->cas($key, @$res), 'First update success');
    ok(! $cache->cas($key, @$res), 'Second update failure');
    is($cache->get($key), 'new value', 'Fetch');

    $res = $cache->gets_multi(@extra_keys);
    isa_ok($res, 'HASH');
    is(scalar keys %$res, scalar @keys, 'Number of entries in result');
    $count = 0;
    foreach my $k (@keys) {
        ++$count if ref($res->{$k}) eq 'ARRAY';
        ++$count if @{$res->{$k}} == 2;
        ++$count if defined $res->{$k}->[0];
        ++$count if $res->{$k}->[1] eq $k;
    }
    is($count, count * 4);

    my $hash = $res;
    $res = $cache->cas_multi([$keys[0], @{$hash->{$keys[0]}}],
                                  ['no-such-key', 123, 'value', 10],
                                  [$keys[1], @{$hash->{$keys[1]}}, 1000]);
    isa_ok($res, 'HASH');
    is(scalar keys %$res, 3);
    ok($res->{$keys[0]});
    ok(defined $res->{'no-such-key'} and not $res->{'no-such-key'});
    ok($res->{$keys[1]});

    my @res = $cache->cas_multi([$keys[2], @{$hash->{$keys[2]}}],
                                     ['no-such-key', 123, 'value', 10],
                                     [$keys[3], @{$hash->{$keys[3]}}, 1000]);
    is(@res, 3);
    ok($res[0]);
    ok(not $res[1]);
    ok($res[2]);

    $res = $cache->cas_multi();
    isa_ok($res, 'HASH');
    is(scalar keys %$res, 0);
}

SKIP: {
    skip "memcached 1.4.8 is required for touch commands", 3
      if $version_num < 10408;
    ok($cache->touch($keys[0]), 'Touch');
    my $res = $cache->touch_multi(map { [$_,0] } @keys);
    is(scalar keys %$res, scalar @keys, 'Number of entries in result');
    is((grep { $_ != 1 } values %$res), 0);
}

ok($cache->replace_multi(map { [$_,0] } @keys),'replace_multi to reset to numeric');

$res = $cache->incr_multi([$keys[0], 2], [$keys[1]], @keys[2..$#keys]);
ok(values %$res == @keys);
is((grep { $_ != 1 } values %$res), 1);
is($res->{$keys[0]}, 2);

$res = $cache->delete_multi($keys1[0]);
ok($res->{$keys1[0]});
$res = $cache->delete_multi([$keys[0]], $keys[1]);
ok($res->{$keys[0]} and $res->{$keys[1]});

ok($cache->remove($keys[2]));
@res = $cache->delete_multi(@keys);
is(@res, count);
is((grep { not $_ } @res), 3);

my $get_or_set_counter=0;
is($cache->get_or_set('get or set',sub {
    $get_or_set_counter++;
    'get_and_set'
},10), 'get_and_set');
is($cache->get_or_set('get or set',sub {
    $get_or_set_counter++; #do not call
    'get_and_set'
},10), 'get_and_set');
is($get_or_set_counter,1);

done_testing();


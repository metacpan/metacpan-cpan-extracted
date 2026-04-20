use strict;
use warnings;
use Test::More;

# UTF-8 flag should NOT participate in key identity or hashing.
# It's metadata controlling how a stored key is returned from iteration,
# not part of the key itself — matches native Perl hash semantics.
#
# Keys with the same bytes but different UTF-8 flag must collide into
# the same slot; keys with different bytes remain distinct.

use Data::HashMap::SS;
use Data::HashMap::SI;
use Data::HashMap::SI16;
use Data::HashMap::SI32;
use Data::HashMap::IS;
use Data::HashMap::SA;

# ---- SS: string keys, string values ----

{
    my $m = Data::HashMap::SS->new();
    my $plain = "abc";
    my $flagged = "abc";
    utf8::upgrade($flagged);
    ok !utf8::is_utf8($plain), 'plain: no flag';
    ok  utf8::is_utf8($flagged), 'flagged: utf8 on';
    is $plain, $flagged, 'identical bytes + string equal';

    hm_ss_put $m, $plain, "v1";
    is(hm_ss_size $m, 1, 'SS: first put → size 1');
    is(hm_ss_get $m, $flagged, "v1", 'SS: lookup with toggled flag finds entry');

    hm_ss_put $m, $flagged, "v2";
    is(hm_ss_size $m, 1, 'SS: put with toggled flag updates, no new entry');
    is(hm_ss_get $m, $plain, "v2", 'SS: plain lookup sees updated value');
    is(hm_ss_get $m, $flagged, "v2", 'SS: flagged lookup sees updated value');

    hm_ss_remove $m, $plain;
    is(hm_ss_size $m, 0, 'SS: remove via plain succeeds');
}

# ---- SI: string keys, int values ----

{
    my $m = Data::HashMap::SI->new();
    my $plain = "hello";
    my $flagged = "hello";
    utf8::upgrade($flagged);

    hm_si_put $m, $plain, 42;
    is(hm_si_get $m, $flagged, 42, 'SI: lookup with toggled flag finds');
    hm_si_put $m, $flagged, 99;
    is(hm_si_size $m, 1, 'SI: size stays 1 after re-put with flag');
    is(hm_si_get $m, $plain, 99, 'SI: updated value via plain lookup');
}

# ---- Counter path (incr/decr) must also collapse on flag ----
# put/get use find_slot_for_insert/find_node; incr uses find_or_allocate
# (a third independent probe loop). All three must strip the UTF-8 flag.
# Keywords aren't capturable as coderefs, so unroll per variant.

{
    my $m = Data::HashMap::SI->new();
    my $plain = "ctr"; my $flagged = "ctr"; utf8::upgrade($flagged);
    hm_si_put $m, $plain, 10;
    is(hm_si_incr $m, $flagged, 11, 'SI: incr with toggled flag finds existing key');
    is(hm_si_size $m, 1, 'SI: incr does not create phantom entry');
    is(hm_si_get $m, $plain, 11, 'SI: plain lookup sees incremented value');

    my $m2 = Data::HashMap::SI->new();
    my $p2 = "new"; my $f2 = "new"; utf8::upgrade($f2);
    hm_si_incr $m2, $p2;
    hm_si_put $m2, $f2, 99;
    is(hm_si_size $m2, 1, 'SI: incr-then-put with toggled flag updates');
    is(hm_si_get $m2, $p2, 99, 'SI: updated value visible');
}

{
    my $m = Data::HashMap::SI16->new();
    my $plain = "ctr"; my $flagged = "ctr"; utf8::upgrade($flagged);
    hm_si16_put $m, $plain, 10;
    is(hm_si16_incr $m, $flagged, 11, 'SI16: incr with toggled flag finds existing key');
    is(hm_si16_size $m, 1, 'SI16: incr does not create phantom entry');
    is(hm_si16_get $m, $plain, 11, 'SI16: plain lookup sees incremented value');
}

{
    my $m = Data::HashMap::SI32->new();
    my $plain = "ctr"; my $flagged = "ctr"; utf8::upgrade($flagged);
    hm_si32_put $m, $plain, 10;
    is(hm_si32_incr $m, $flagged, 11, 'SI32: incr with toggled flag finds existing key');
    is(hm_si32_size $m, 1, 'SI32: incr does not create phantom entry');
    is(hm_si32_get $m, $plain, 11, 'SI32: plain lookup sees incremented value');
}

# ---- IS: int keys, string values — verify flag preserved in VALUE ----

{
    my $m = Data::HashMap::IS->new();
    my $flagged_val = "v";
    utf8::upgrade($flagged_val);
    hm_is_put $m, 1, $flagged_val;
    my $got = hm_is_get $m, 1;
    ok utf8::is_utf8($got), 'IS: value utf8 flag preserved on retrieval';
}

# ---- SA: string keys, any SV values ----

{
    my $m = Data::HashMap::SA->new();
    my $plain = "key";
    my $flagged = "key";
    utf8::upgrade($flagged);

    hm_sa_put $m, $plain, [1];
    is_deeply(hm_sa_get $m, $flagged, [1], 'SA: toggled-flag lookup finds');
    hm_sa_put $m, $flagged, [2];
    is(hm_sa_size $m, 1, 'SA: toggled-flag re-put updates');
    is_deeply(hm_sa_get $m, $plain, [2], 'SA: plain lookup sees update');
}

# ---- Regression: different-byte strings remain distinct ----
# "\xC3\xA9" (Latin-1, 2 bytes, flag off) vs "\x{E9}" (1 byte, flag on).
# These have different byte content and must NOT collide.

{
    my $m = Data::HashMap::SS->new();
    my $latin1 = "\xC3\xA9";      # 2 bytes, flag off
    my $ucp    = "\x{E9}";         # 1 byte, flag on
    ok length($latin1) != length($ucp),
        'different byte lengths for regression test';

    hm_ss_put $m, $latin1, "l1";
    hm_ss_put $m, $ucp,    "ucp";
    is(hm_ss_size $m, 2, 'different-byte keys remain distinct');
    is(hm_ss_get $m, $latin1, "l1", 'Latin-1 key preserved');
    is(hm_ss_get $m, $ucp,    "ucp", 'Unicode-codepoint key preserved');
}

# ---- Retrieval flag follows most-recent put ----

{
    my $m = Data::HashMap::SS->new();
    my $plain = "k";
    my $flagged = "k"; utf8::upgrade($flagged);

    hm_ss_put $m, $plain, "a";
    hm_ss_put $m, $flagged, "b";  # updates, flag now on for stored key

    my @keys = hm_ss_keys $m;
    is scalar(@keys), 1, 'one key after toggle put';
    ok utf8::is_utf8($keys[0]),
        'stored key reflects flag from most-recent put';
}

done_testing;

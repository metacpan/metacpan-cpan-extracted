#!/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use Arcus::Client;

use FindBin;
use lib "$FindBin::Bin";
use ArcusTestCommon;

if (not ArcusTestCommon->is_zk_port_opened()) {
  plan skip_all => "zk is not running...";
}

open(STDERR, '>', '/dev/null');

my $cache = ArcusTestCommon->create_client("perl-test:");
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

my @kvs = (
  [ "kv01", { "field1" => "elem1" } ],
  [ "kv02", "val02" ],
  [ "kv03", [ "elem1", "elem2" ] ],
);
my $href = $cache->set_multi(@kvs);
for my $key ( "kv01", "kv02", "kv03" ) {
  ok($href->{$key});
}
is_deeply($cache->get("kv01"), { "field1" => "elem1" });
is_deeply($cache->get("kv02"), "val02");
is_deeply($cache->get("kv03"), [ "elem1", "elem2" ]);

my $MAX_KEY_SIZE = 1000;
my $TEST_CASE_SIZE = 4000;

my @chars = ('A'..'Z', 'a'..'z', ' ', '🐳');
sub random_string {
  my $MAX_SIZE = shift;
  my ($str, $len) = ('', int(rand($MAX_SIZE)) + 1);
  for (1..$len) {
    $str .= $chars[int(rand(@chars))];
  }
  return $str;
}

my (@test_keys, @test_values);

for my $i (1..$TEST_CASE_SIZE) {
  push(@test_keys, $i.random_string($MAX_KEY_SIZE));
  if ($i >= $TEST_CASE_SIZE / 10) {
    push(@test_values, int(rand($i)));
  } else {
    my %hash = map { $i.random_string(5) => $_ } 1..5;
    push(@test_values, \%hash);
  }
}

@kvs = map { [$test_keys[$_], $test_values[$_]] } 0..$#test_keys;

$href = $cache->add_multi(@kvs);
my $is_success = 1;
for my $key (@test_keys) {
  $is_success = 0 unless $href->{$key};
}
ok($is_success, "Multi Add Test");

my @replace_kvs = map { [$test_keys[$_], $_] } 0..$#test_keys;
$href = $cache->replace_multi(@replace_kvs);
$is_success = 1;
for my $key (@test_keys) {
  $is_success = 0 unless $href->{$key};
}
ok($is_success, "Multi Replace Test");

$href = $cache->get_multi(@test_keys);
$is_success = 1;
for my $i (0..$#test_keys) {
    $is_success = 0 unless eq_deeply($href->{$test_keys[$i]}, $i);
}
ok($is_success, "Multi Get Test");

$href = $cache->set_multi(@kvs);
$is_success = 1;
for my $key (@test_keys) {
  $is_success = 0 unless $href->{$key};
}
ok($is_success, "Multi Set Test");

$href = $cache->get_multi(@test_keys);
$is_success = 1;
for my $i (0..$#test_keys) {
  if (ref $href->{$test_keys[$i]}) {
    $is_success = 0 unless eq_deeply($href->{$test_keys[$i]}, $test_values[$i]);
  } else {
    $is_success = 0 unless ($href->{$test_keys[$i]} eq $test_values[$i]);
  }
}
ok($is_success, "Multi Get Test");

ok($cache->flush_all, "Flush All");

ok($cache->set("key1", "value1"));
ok($cache->set("key2", "value2"));
my $expected = {
  "key1" => "value1",
  "key2" => "value2"
};

is_deeply($cache->get_multi(), {}, "Multi Get With Empty Keys Returns Empty Hash");
is_deeply($cache->get_multi(undef, undef), {}, "Multi Get With Keys Filled With Undef Returns Empty Hash");
is_deeply($cache->get_multi("key1", undef, "key2"), $expected, "Multi Get With Keys Containing Undef Returns Only Valid Keys");
is_deeply($cache->get_multi(undef, "key1", undef, "key2"), $expected, "Multi Get With Keys Containing Undef Returns Only Valid Keys");
is_deeply($cache->get_multi("key1", "", "key2"), $expected, "Multi Get With Keys Containing Empty String Returns Only Valid Keys");
is_deeply($cache->get_multi("", "key1", "", "key2"), $expected, "Multi Get With Keys Containing Empty String Returns Only Valid Keys");
is_deeply($cache->get_multi(undef, "key1", "", "key2"), $expected, "Multi Get With Keys Containing Undef And Empty String Returns Only Valid Keys");
is_deeply($cache->get_multi("", "key1", undef, "key2"), $expected, "Multi Get With Keys Containing Undef And Empty String Returns Only Valid Keys");

my @kvs_expt = map { [$test_keys[$_], $test_values[$_], time() - 1] } 0..$#test_keys;

$href = $cache->set_multi(@kvs_expt);
$is_success = 1;
for my $key (@test_keys) {
  $is_success = 0 unless $href->{$key};
  $is_success = 0 if defined $cache->get($key);
}
ok($is_success, "Multi Set Test With Exptime Success Store And Expired");

ok($cache->flush_all, "Flush All");

$href = $cache->get_multi(@test_keys);
is_deeply($href, {}, "Multi Get All Cache Miss Returns Empty Hash");

ok($cache->set("key", ""));
is_deeply($cache->get_multi("key"), { "key" => "" }, "Multi Get After Set Empty String Returns Empty String");

ok($cache->flush_all, "Flush All");

$href = $cache->set_multi();
is_deeply($href, {}, "Multi Set With Empty Argument Returns Empty Hash");

$href = $cache->set_multi(undef, undef);
is_deeply($href, {}, "Multi Set With KVs Filled With Undef Returns Empty Hash");

my $big_value = 'x' x ( 1024 * 1024 * 10 );
sub test_set_multi_containing_invalid_kvs {
  @kvs = (
    undef,
    [],
    undef,
    [ "key1", "value1" ],
    [ "", "value-empty-key" ],
    [ undef, "value-undef-key" ],
    [ "key2", "value2" ],
    [],
    undef,
    [ "key-invalid-exptime", "value3", "exptime" ],
    [ "key-no-value" ],
    [ "key-empty-value", "" ],
    [ "key-undef-value", undef ],
    undef,
    [ "key3", "value3", 30 ],
    [],
    undef,
    [ "key-big-value", $big_value ],
  );
  $expected = {
    "key1" => 1,
    "key2" => 1,
    "key3" => 1,
    "key-empty-value" => 1,
  };

  $href = $cache->set_multi(@kvs);
  is_deeply($href, $expected, "Multi Set With Key-Values Containing Invalid Key-Values Returns For Only Valid Key-Values");

  is($href->{"key1"}, 1);
  is($href->{"key2"}, 1);
  is($href->{"key3"}, 1);
  is($href->{"key-empty-value"}, 1);

  is($href->{""}, undef);
  is($href->{"key-invalid-exptime"}, undef);
  is($href->{"key-no-value"}, undef);
  is($href->{"key-undef-value"}, undef);
  is($href->{"key-big-value"}, undef);

  is($cache->get("key1"), "value1");
  is($cache->get("key2"), "value2");
  is($cache->get("key3"), "value3");
  is($cache->get("key-empty-value"), "");

  is($cache->get(""), undef);
  is($cache->get("key-invalid-exptime"), undef);
  is($cache->get("key-no-value"), undef);
  is($cache->get("key-undef-value"), undef);
  is($cache->get("key-big-value"), undef);
}

test_set_multi_containing_invalid_kvs();
ok($cache->flush_all, "Flush All");

$cache = ArcusTestCommon->create_client();
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

test_set_multi_containing_invalid_kvs();
ok($cache->flush_all, "Flush All");

@kvs = (
  [ "key1", "value1" ],
  [ "key2", "value2" ],
  [ "key-big-value", $big_value ],
);
$expected = {
  "key1" => 1,
  "key2" => 1,
};

$href = $cache->set_multi(@kvs);
is_deeply($href, $expected);
is($href->{"key-big-value"}, undef);

my @keys = ( "key1", "key2", "key-big-value" );
$href = $cache->get_multi(@keys);
is_deeply($href, {"key1" => "value1", "key2" => "value2"});
is($href->{"key-big-value"}, undef);

push(@kvs, [ "key3", "value3" ]);
$expected = {
  "key1" => 0,
  "key2" => 0,
  "key3" => 1,
};

$href = $cache->add_multi(@kvs);
is_deeply($href, $expected);
is($href->{"key-big-value"}, undef);

push(@keys, "key3");
$href = $cache->get_multi(@keys);
is_deeply($href, {"key1" => "value1", "key2" => "value2", "key3" => "value3"});
is($href->{"key-big-value"}, undef);

@kvs = (
  [ "key1", "value1-replaced" ],
  [ "key2", "value2-replaced" ],
  [ "key-not-exists", "value-not-exists" ],
  [ "key-big-value", $big_value ],
);
$expected = {
  "key1" => 1,
  "key2" => 1,
  "key-not-exists" => 0,
};

$href = $cache->replace_multi(@kvs);
is_deeply($href, $expected);
is($href->{"key-big-value"}, undef);

push(@keys, "key-not-exists");
$href = $cache->get_multi(@keys);
is_deeply($href, {"key1" => "value1-replaced", "key2" => "value2-replaced", "key3" => "value3"});
is($href->{"key-big-value"}, undef);
is($href->{"key-not-exists"}, undef);

$kvs[0]->[1] = "value1-prepend-";
$kvs[1]->[1] = "value2-prepend-";
$expected = {
  "key1" => 1,
  "key2" => 1,
  "key-not-exists" => 0,
};
$href = $cache->prepend_multi(@kvs);
is_deeply($href, $expected);
is($href->{"key-big-value"}, undef);

$href = $cache->get_multi(@keys);
is_deeply($href, {
  "key1" => "value1-prepend-value1-replaced",
  "key2" => "value2-prepend-value2-replaced",
  "key3" => "value3"
});
is($href->{"key-big-value"}, undef);
is($href->{"key-not-exists"}, undef);

$kvs[0]->[1] = "-value1-append";
$kvs[1]->[1] = "-value2-append";
$expected = {
  "key1" => 1,
  "key2" => 1,
  "key-not-exists" => 0,
};
$href = $cache->append_multi(@kvs);
is_deeply($href, $expected);
is($href->{"key-big-value"}, undef);

$href = $cache->get_multi(@keys);
is_deeply($href, {
  "key1" => "value1-prepend-value1-replaced-value1-append",
  "key2" => "value2-prepend-value2-replaced-value2-append",
  "key3" => "value3"
});
is($href->{"key-big-value"}, undef);
is($href->{"key-not-exists"}, undef);

ok($cache->flush_all, "Flush All");

@kvs = (
  [ "key1", 1, "value1" ],
  [ "key2", 1, "value2" ],
  [ "key3", 1, "value3" ],
  [ "key4", 1, "value4" ],
  [ "key5", 1, "value5" ],
  [ "key6", 1, "value6" ],
  [ "key7", 1, "value7" ],
  [ "key8", 1, "value8" ],
);
$expected = {
  "key1" => 0,
  "key2" => 0,
  "key3" => 0,
  "key4" => 0,
  "key5" => 0,
  "key6" => 0,
  "key7" => 0,
  "key8" => 0,
};

$href = $cache->cas_multi(@kvs);
is_deeply($href, $expected, "Cas Multi To Not Stored Values Returns Hash Filled With False");

@kvs = (
  [ "key1", "value1" ],
  [ "key2", "value2" ],
  [ "key3", "value3" ],
  [ "key4", "value4" ],
  [ "key5", "value5" ],
  [ "key6", "value6" ],
  [ "key7", "value7" ],
  [ "key8", "value8" ],
);
$expected = {
  "key1" => 1,
  "key2" => 1,
  "key3" => 1,
  "key4" => 1,
  "key5" => 1,
  "key6" => 1,
  "key7" => 1,
  "key8" => 1,
};

$href = $cache->set_multi(@kvs);
is_deeply($href, $expected);

@keys = ("key1", "key2", "key3", "key4", "key5", "key6", "key7", "key8");

$href = $cache->gets_multi(@keys);
is($href->{"key1"}->[1], "value1");
is($href->{"key2"}->[1], "value2");
is($href->{"key3"}->[1], "value3");
is($href->{"key4"}->[1], "value4");
is($href->{"key5"}->[1], "value5");
is($href->{"key6"}->[1], "value6");
is($href->{"key7"}->[1], "value7");
is($href->{"key8"}->[1], "value8");

@kvs = (
  [ "key1", $href->{"key1"}->[0], "value1-changed" ],
  [ "key2", $href->{"key2"}->[0], "value2-changed" ],
  [ "key3", $href->{"key3"}->[0], "value3-changed" ],
  [ "key4", $href->{"key4"}->[0], "value4-changed" ],
  [ "key5", $href->{"key5"}->[0], "value5-changed" ],
  [ "key6", $href->{"key6"}->[0], "value6-changed" ],
  [ "key7", $href->{"key7"}->[0], "value7-changed" ],
  [ "key8", $href->{"key8"}->[0], "value8-changed" ],
);
$expected = {
  "key1" => 1,
  "key2" => 1,
  "key3" => 1,
  "key4" => 1,
  "key5" => 1,
  "key6" => 1,
  "key7" => 1,
  "key8" => 1,
};

$href = $cache->cas_multi(@kvs);
is_deeply($href, $expected, "Cas Multi To Stored Values Returns Hash Filled With True");

$href = $cache->gets_multi(@keys);
is($href->{"key1"}->[1], "value1-changed");
is($href->{"key2"}->[1], "value2-changed");
is($href->{"key3"}->[1], "value3-changed");
is($href->{"key4"}->[1], "value4-changed");
is($href->{"key5"}->[1], "value5-changed");
is($href->{"key6"}->[1], "value6-changed");
is($href->{"key7"}->[1], "value7-changed");
is($href->{"key8"}->[1], "value8-changed");

@kvs = (
  [ "key1", 0, "value1-changed-changed" ],
  [ "key2", undef, "value2-changed-changed" ],
  [ "key3", "string cas value", "value2-changed-changed" ],
  [ "key4", 1, "value4-valid-request" ],
  [ "key5", $href->{"key5"}->[0], undef ],
  [ "key6", $href->{"key6"}->[0], "" ],
  [ "key7", $href->{"key7"}->[0], "value7-valid-request" ],
  [ "", $href->{"key8"}->[0], "value8-invalid-request" ],
);
$expected = {
  "key4" => 0,
  "key6" => 1,
  "key7" => 1,
};

$href = $cache->cas_multi(@kvs);
is_deeply($href, $expected, "Cas Multi Containing Invalid Arguments Returns Only For Valid Arguments");

$href = $cache->gets_multi(@keys);
is($href->{"key1"}->[1], "value1-changed", "Must Be Old Value");
is($href->{"key2"}->[1], "value2-changed", "Must Be Old Value");
is($href->{"key3"}->[1], "value3-changed", "Must Be Old Value");
is($href->{"key4"}->[1], "value4-changed", "Must Be Old Value");
is($href->{"key5"}->[1], "value5-changed", "Must Be Old Value");
is($href->{"key6"}->[1], "", "Must Be New Value");
is($href->{"key7"}->[1], "value7-valid-request", "Must Be New Value");
is($href->{"key8"}->[1], "value8-changed", "Must Be Old Value");

ok($cache->flush_all, "Flush All");
done_testing();

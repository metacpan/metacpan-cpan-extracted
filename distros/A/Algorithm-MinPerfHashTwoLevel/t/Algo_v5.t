#########################

use strict;
use warnings;

use Test::More tests => 7;
use Data::Dumper; $Data::Dumper::Sortkeys=1; $Data::Dumper::Useqq=1;
BEGIN { use_ok('Algorithm::MinPerfHashTwoLevel') };
use Algorithm::MinPerfHashTwoLevel qw(hash_with_state);

#########################

my $class= "Algorithm::MinPerfHashTwoLevel";

my $o= $class->new("seed"=>"1234567812345678",debug=>$ENV{TEST_VERBOSE},variant=>5);
my $state= $o->get_state;
my $state_as_hex= unpack "h*",$o->get_state;
is($state_as_hex,"4475044405b585b4c5d575a5454485c5050465a50515e445247574d4752525c4","state for seed is as expected");
for my $tuple (
    [ "fnorble",        17300635747579776751 ],
    [ "blah blah blah",  7551733764733872358 ],
    [ "blah blaH blah", 15370689535882563083 ],
) {
    my ($str,$want_hash)= @$tuple;
    my $got_hash= hash_with_state($str,$state);
    is($got_hash,$want_hash,"test hash function '$str'");
}

my %hash= ("A" .. "Z");
my $buckets= $o->compute(\%hash);
is_deeply($buckets,
    [
           {
             "h0" => "2811388775115704789",
             "idx" => 0,
             "key" => "M",
             "key_is_utf8" => 0,
             "key_normalized" => "M",
             "val" => "N",
             "val_is_utf8" => 0,
             "val_normalized" => "N"
           },
           {
             "h0" => "8860848721851830215",
             "h1_keys" => 2,
             "idx" => 1,
             "key" => "K",
             "key_is_utf8" => 0,
             "key_normalized" => "K",
             "val" => "L",
             "val_is_utf8" => 0,
             "val_normalized" => "L",
             "xor_val" => 1
           },
           {
             "h0" => "2333874141850904510",
             "h1_keys" => 1,
             "idx" => 2,
             "key" => "G",
             "key_is_utf8" => 0,
             "key_normalized" => "G",
             "val" => "H",
             "val_is_utf8" => 0,
             "val_normalized" => "H",
             "xor_val" => "4294967295"
           },
           {
             "h0" => "16876117158654460122",
             "idx" => 3,
             "key" => "Y",
             "key_is_utf8" => 0,
             "key_normalized" => "Y",
             "val" => "Z",
             "val_is_utf8" => 0,
             "val_normalized" => "Z"
           },
           {
             "h0" => "8715353882719101949",
             "h1_keys" => 1,
             "idx" => 4,
             "key" => "S",
             "key_is_utf8" => 0,
             "key_normalized" => "S",
             "val" => "T",
             "val_is_utf8" => 0,
             "val_normalized" => "T",
             "xor_val" => "4294967294"
           },
           {
             "h0" => "7118026915973626049",
             "h1_keys" => 1,
             "idx" => 5,
             "key" => "U",
             "key_is_utf8" => 0,
             "key_normalized" => "U",
             "val" => "V",
             "val_is_utf8" => 0,
             "val_normalized" => "V",
             "xor_val" => "4294967293"
           },
           {
             "h0" => "8257329964001049281",
             "h1_keys" => 2,
             "idx" => 6,
             "key" => "O",
             "key_is_utf8" => 0,
             "key_normalized" => "O",
             "val" => "P",
             "val_is_utf8" => 0,
             "val_normalized" => "P",
             "xor_val" => 1
           },
           {
             "h0" => "5518171323424817881",
             "h1_keys" => 1,
             "idx" => 7,
             "key" => "E",
             "key_is_utf8" => 0,
             "key_normalized" => "E",
             "val" => "F",
             "val_is_utf8" => 0,
             "val_normalized" => "F",
             "xor_val" => "4294967291"
           },
           {
             "h0" => "3591181703942984702",
             "h1_keys" => 1,
             "idx" => 8,
             "key" => "Q",
             "key_is_utf8" => 0,
             "key_normalized" => "Q",
             "val" => "R",
             "val_is_utf8" => 0,
             "val_normalized" => "R",
             "xor_val" => "4294967288"
           },
           {
             "h0" => "8458370515337648683",
             "h1_keys" => 1,
             "idx" => 9,
             "key" => "W",
             "key_is_utf8" => 0,
             "key_normalized" => "W",
             "val" => "X",
             "val_is_utf8" => 0,
             "val_normalized" => "X",
             "xor_val" => "4294967286"
           },
           {
             "h0" => "18153270191496908466",
             "idx" => 10,
             "key" => "C",
             "key_is_utf8" => 0,
             "key_normalized" => "C",
             "val" => "D",
             "val_is_utf8" => 0,
             "val_normalized" => "D"
           },
           {
             "h0" => "5043040936135718210",
             "h1_keys" => 2,
             "idx" => 11,
             "key" => "A",
             "key_is_utf8" => 0,
             "key_normalized" => "A",
             "val" => "B",
             "val_is_utf8" => 0,
             "val_normalized" => "B",
             "xor_val" => 2
           },
           {
             "h0" => "15354065489600908969",
             "h1_keys" => 1,
             "idx" => 12,
             "key" => "I",
             "key_is_utf8" => 0,
             "key_normalized" => "I",
             "val" => "J",
             "val_is_utf8" => 0,
             "val_normalized" => "J",
             "xor_val" => "4294967285"
           }
    ],
    "simple hash A-Z",
) or diag Dumper($buckets);

%hash=map {
    my $key= chr($_);
    utf8::upgrade($key) if $_ % 2;
    $key => $key
} 250 .. 260;
$buckets= $o->compute(\%hash);
is_deeply($buckets,
    [
           {
             "h0" => "7329038856428266488",
             "h1_keys" => 1,
             "idx" => 0,
             "key" => "\376",
             "key_is_utf8" => 0,
             "key_normalized" => "\376",
             "val" => "\376",
             "val_is_utf8" => 0,
             "val_normalized" => "\376",
             "xor_val" => "4294967293"
           },
           {
             "h0" => "7406429479659263986",
             "h1_keys" => 2,
             "idx" => 1,
             "key" => "\x{101}",
             "key_is_utf8" => 1,
             "key_normalized" => "\304\201",
             "val" => "\x{101}",
             "val_is_utf8" => 1,
             "val_normalized" => "\304\201",
             "xor_val" => 2
           },
           {
             "h0" => "7026079938176527097",
             "h1_keys" => 1,
             "idx" => 2,
             "key" => "\x{103}",
             "key_is_utf8" => 1,
             "key_normalized" => "\304\203",
             "val" => "\x{103}",
             "val_is_utf8" => 1,
             "val_normalized" => "\304\203",
             "xor_val" => "4294967292"
           },
           {
             "h0" => "2560445542346638988",
             "idx" => 3,
             "key" => "\x{100}",
             "key_is_utf8" => 1,
             "key_normalized" => "\304\200",
             "val" => "\x{100}",
             "val_is_utf8" => 1,
             "val_normalized" => "\304\200"
           },
           {
             "h0" => "15075586565050556610",
             "h1_keys" => 3,
             "idx" => 4,
             "key" => "\x{102}",
             "key_is_utf8" => 1,
             "key_normalized" => "\304\202",
             "val" => "\x{102}",
             "val_is_utf8" => 1,
             "val_normalized" => "\304\202",
             "xor_val" => 1
           },
           {
             "h0" => "10520228168695442556",
             "h1_keys" => 1,
             "idx" => 5,
             "key" => "\x{ff}",
             "key_is_utf8" => 2,
             "key_normalized" => "\377",
             "val" => "\x{ff}",
             "val_is_utf8" => 1,
             "val_normalized" => "\303\277",
             "xor_val" => "4294967290"
           },
           {
             "h0" => "10697593882658072482",
             "h1_keys" => 1,
             "idx" => 6,
             "key" => "\372",
             "key_is_utf8" => 0,
             "key_normalized" => "\372",
             "val" => "\372",
             "val_is_utf8" => 0,
             "val_normalized" => "\372",
             "xor_val" => "4294967286"
           },
           {
             "h0" => "12905152200806003791",
             "idx" => 7,
             "key" => "\374",
             "key_is_utf8" => 0,
             "key_normalized" => "\374",
             "val" => "\374",
             "val_is_utf8" => 0,
             "val_normalized" => "\374"
           },
           {
             "h0" => "11318277185996573588",
             "idx" => 8,
             "key" => "\x{fd}",
             "key_is_utf8" => 2,
             "key_normalized" => "\375",
             "val" => "\x{fd}",
             "val_is_utf8" => 1,
             "val_normalized" => "\303\275"
           },
           {
             "h0" => "11837163118808456557",
             "idx" => 9,
             "key" => "\x{104}",
             "key_is_utf8" => 1,
             "key_normalized" => "\304\204",
             "val" => "\x{104}",
             "val_is_utf8" => 1,
             "val_normalized" => "\304\204"
           },
           {
             "h0" => "13939891494320893160",
             "h1_keys" => 2,
             "idx" => 10,
             "key" => "\x{fb}",
             "key_is_utf8" => 2,
             "key_normalized" => "\373",
             "val" => "\x{fb}",
             "val_is_utf8" => 1,
             "val_normalized" => "\303\273",
             "xor_val" => 2
           }
    ],
    "hash with utf8 works as expected",
) or diag Dumper($buckets);



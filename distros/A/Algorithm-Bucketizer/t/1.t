# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 8 };
use Algorithm::Bucketizer;
ok(1); # If we made it this far, we're ok.

#########################
# Simple case from README
#########################

my $out = "";
my $b = Algorithm::Bucketizer->new( bucketsize => 100 );
for my $i (1..10) {
    $b->add_item($i, 30+$i);
}

for my $bucket ($b->buckets()) {
    for my $item ($bucket->items()) {
        $out .= "B" . $bucket->serial() . "I$item ";
    }
}

my $exp = "B1I1 B1I2 B1I3 B2I4 B2I5 B3I6 B3I7 B4I8 B4I9 B5I10 ";

ok($out eq $exp) || warn "Expected '$exp' but got '$out'\n";

#########################
# Simple/Retry
#########################

$out = "";
$b = Algorithm::Bucketizer->new( bucketsize => 10 );
$b->add_item("five", 5);
$b->add_item("six", 6);
$b->add_item("five", 5);
$b->add_item("six", 6);

for my $bucket ($b->buckets()) {
    for my $item ($bucket->items()) {
        $out .= "B" . $bucket->serial() . "I$item ";
    }
}

$exp = "B1Ifive B2Isix B3Ifive B4Isix ";
ok($out eq $exp) || warn "Expected '$exp' but got '$out'\n";

$out = "";
$b = Algorithm::Bucketizer->new( bucketsize => 10,
                                    algorithm  => 'retry' );
$b->add_item("five", 5);
$b->add_item("six", 6);
$b->add_item("five", 5);
$b->add_item("six", 6);

for my $bucket ($b->buckets()) {
    for my $item ($bucket->items()) {
        $out .= "B" . $bucket->serial() . "I$item ";
    }
}

$exp = "B1Ifive B1Ifive B2Isix B3Isix ";
ok($out eq $exp) || warn "Expected '$exp' but got '$out'\n";

#########################
# Preload buckets
#########################

$out = "";
$b = Algorithm::Bucketizer->new( bucketsize => 10,
                                 algorithm  => 'simple' );
$b->prefill_bucket(0, "one", 1);
$b->prefill_bucket(1, "two", 2);

$b->add_item("three", 3);

for my $bucket ($b->buckets()) {
    for my $item ($bucket->items()) {
        $out .= "B" . $bucket->serial() . "I$item ";
    }
}

$exp = "B1Ione B2Itwo B2Ithree ";
ok($out eq $exp) || warn "Expected '$exp' but got '$out'\n";

#########################
# Optimize with brute force
#########################

    # Only if we have Algorithm::Permute
my $skip_this = !eval "require Algorithm::Permute";

if(!$skip_this) {
    $out = "";
    $b = Algorithm::Bucketizer->new( bucketsize => 10,
                                        algorithm  => 'simple' );
    $b->add_item("one",   8);
    $b->add_item("two",   9);
    $b->add_item("three", 2);
    $b->add_item("four",  1);
   
    for my $bucket ($b->buckets()) {
        for my $item ($bucket->items()) {
            $out .= "B" . $bucket->serial() . "I$item ";
        }
    }

    $b->optimize(algorithm => 'brute_force');

    for my $bucket ($b->buckets()) {
        for my $item ($bucket->items()) {
            $out .= "B" . $bucket->serial() . "I$item ";
        }
    }

    $exp = "B1Ione B2Itwo B3Ithree B3Ifour B1Ithree B1Ione B2Itwo B2Ifour ";
    ok($out eq $exp) || warn "Expected '$exp' but got '$out'\n";
} else {
    print STDERR "\n  Skipping optimization (no Algorithm::Permute)\n";
    skip(1, "Skipped");
}

#########################
# Optimize randomly with time limit
#########################

$out = "";
$b = Algorithm::Bucketizer->new( bucketsize => 10,
                                 algorithm  => 'simple' );
$b->add_item("one",   8);
$b->add_item("two",   9);
$b->add_item("three", 2);
$b->add_item("four",  1);

my $nof_buckets = scalar $b->buckets();

$b->optimize(algorithm => 'random', maxtime => "1");

ok(scalar $b->buckets <= $nof_buckets);

#########################
# Optimize randomly with round limit
#########################

$out = "";
$b = Algorithm::Bucketizer->new( bucketsize => 10,
                                 algorithm  => 'simple' );
$b->add_item("one",   8);
$b->add_item("two",   9);
$b->add_item("three", 2);
$b->add_item("four",  1);

$nof_buckets = scalar $b->buckets();

$b->optimize(algorithm => 'random', maxrounds => 20);

ok(scalar $b->buckets <= $nof_buckets);

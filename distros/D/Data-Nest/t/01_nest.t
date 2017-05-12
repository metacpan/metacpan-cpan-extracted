#!perl -T
use strict;
use Test::More;
use Data::Dumper;
use Data::Nest;

sub getSample {
    my $size = shift || 256;
    [map { {
        userid => int(rand(255)),
        itemid => int(rand(255)),
        gender => int(rand(2)),
        quantity => int(rand(255))} } @{[0..$size - 1]}];
};
my $size = 100;

subtest "make instance" => sub {
    my $nest = new Data::Nest();
    ok(exists $nest->{keys}, "has keys");
    is(scalar @{$nest->{keys}}, 0, "keys length is 0");
    ok(exists $nest->{tree}, "has tree");
    is(keys %{$nest->{tree}}, 0, "tree has no keys");
    is($nest->{keyname}, "key", "key name is 'key'");
    is($nest->{valname}, "values", "val name is 'val'");
    is($nest->{delimiter}, "_____", "delimiter is '_____'");
    is($nest->{noValues}, 0, "noValues option is 0");
    ok(exists $nest->{rollups}, "has rollups");
    is(scalar @{$nest->{rollups}}, 0, "rollups length is 0");

    $nest = nest();
    ok(exists $nest->{keys}, "has keys");
    is(scalar @{$nest->{keys}}, 0, "keys length is 0");
    ok(exists $nest->{tree}, "has tree");
    is(keys %{$nest->{tree}}, 0, "tree has no keys");
    is($nest->{keyname}, "key", "key name is 'key'");
    is($nest->{valname}, "values", "val name is 'val'");
    is($nest->{delimiter}, "_____", "delimiter is '_____'");
    is($nest->{noValues}, 0, "noValues option is 0");
    ok(exists $nest->{rollups}, "has rollups");
    is(scalar @{$nest->{rollups}}, 0, "rollups length is 0");
};

subtest "nest default setting" => sub {
    my $nest = new Data::Nest()->key("gender");
    my $res = $nest->entries(&getSample($size));
    my $keys = $nest->key();

    is_deeply($nest->{keys}, [["gender"]], "keys contains 'gender'");
    is_deeply($keys, [["gender"]], "key method return 'gender'");

    foreach my $entry (@$res){
        foreach my $val (@{$entry->{values}}){
            is($val->{gender}, int($entry->{key}), "all values match key");
        }
    }
};

subtest "no values" => sub {
    my $nest = new Data::Nest(noValues => 1)->key("gender");
    my $res = $nest->entries(&getSample($size));
    my $keys = $nest->key();

    is_deeply($nest->{keys}, [["gender"]], "keys contains 'gender'");
    is_deeply($keys, [["gender"]], "key method return 'gender'");

    foreach my $entry (@$res){
        ok(! exists $entry->{values}, "length 0 when no rollup function ");
    }
};

subtest "add key (two key)" => sub {
    my $nest = new Data::Nest()->key("gender", "userid");
    my $res = $nest->entries(&getSample($size));
    my $keys = $nest->key();

    is_deeply($nest->{keys}, [["gender", "userid"]], "keys contains 'gender', 'userid'");
    is_deeply($keys, [["gender", "userid"]], "keys contains 'gender', 'userid'");

    foreach my $entry (@$res){
        my ($gender, $userid) = split $nest->{delimiter}, $entry->{key};
        foreach my $val (@{$entry->{values}}){
            is($val->{gender}, int($gender), "all values match first key");
            is($val->{userid}, int($userid), "all values match second key");
        }
    }
};

subtest "add key (two key) with custom delimiter" => sub {
    my $nest = new Data::Nest(delimiter => ",")->key("gender", "userid");
    my $res = $nest->entries(&getSample($size));
    my $keys = $nest->key();

    is_deeply($nest->{keys}, [["gender", "userid"]], "keys contains 'gender', 'userid'");
    is_deeply($keys, [["gender", "userid"]], "keys contains 'gender', 'userid'");

    foreach my $entry (@$res){
        my ($gender, $userid) = split $nest->{delimiter}, $entry->{key};
        foreach my $val (@{$entry->{values}}){
            is($val->{gender}, int($gender), "all values match first key");
            is($val->{userid}, int($userid), "all values match second key");
        }
    }
};

subtest "add key twice" => sub {
    my $nest = new Data::Nest()->key("userid")->key('itemid');
    my $res = $nest->entries(&getSample($size));
    my $keys = $nest->key();

    is_deeply($nest->{keys}, [["userid"], ["itemid"]], "keys contains 'userid' and 'itemid'");
    is_deeply($keys, [["userid"], ["itemid"]], "keys contains 'userid' and 'itemid'");

    foreach my $first_entry (@$res){
        foreach my $second_entry (@{$first_entry->{values}}){
            foreach my $val (@{$second_entry->{values}}){
                is($val->{userid}, int($first_entry->{key}), "all values match first key");
                is($val->{itemid}, int($second_entry->{key}), "all values match second key");
            }
        }
    }
};

subtest "add key more than twice" => sub {
    my $nest = new Data::Nest()->key("userid")->key('itemid')->key("quantity");
    my $res = $nest->entries(&getSample($size));
    my $keys = $nest->key();

    is_deeply($nest->{keys}, [["userid"], ["itemid"], ["quantity"]], "keys contains 'userid', 'itemid' and 'quantity'");
    is_deeply($keys, [["userid"], ["itemid"], ["quantity"]], "keys contains 'userid', 'itemid' and 'quantity'");

    foreach my $first_entry (@$res){
        foreach my $second_entry (@{$first_entry->{values}}){
            foreach my $third_entry (@{$second_entry->{values}}){
                foreach my $val (@{$third_entry->{values}}){
                    is($val->{userid}, int($first_entry->{key}), "all values match first key");
                    is($val->{itemid}, int($second_entry->{key}), "all values match second key");
                    is($val->{quantity}, int($third_entry->{key}), "all values match third key");
                }
            }
        }
    }
};

subtest "add CODE key" => sub {
    my $keyFunc = sub { my $d = shift; int($d->{quantity} / 10) * 10;};
    my $nest = new Data::Nest()->key($keyFunc);
    my $res = $nest->entries(&getSample($size));

    ok(ref $nest->{keys}[0][0] eq "CODE", "keys contains CODE");
    is($nest->{keys}[0][0]->({quantity => 65}), 60, "keys execute");

    foreach my $entry (@$res){
        foreach my $val (@{$entry->{values}}){
            is($keyFunc->($val), $entry->{key}, "all values match key");
        }
    }
};

subtest "add CODE key twice" => sub {
    my $firstKey = sub { my $d = shift; int($d->{quantity} / 10) * 10; };
    my $secondKey = sub { my $d = shift; $d->{userid} % 2; };
    my $nest = new Data::Nest()
        ->key($firstKey)
        ->key($secondKey);
    my $res = $nest->entries(&getSample($size));

    ok(ref $nest->{keys}[0][0] eq "CODE", "1st key is CODE");
    ok(ref $nest->{keys}[1][0] eq "CODE", "2nd key is CODE");
    is($nest->{keys}[0][0]->({quantity => 65, userid => 3}), 60, "1st key execute");
    is($nest->{keys}[1][0]->({quantity => 65, userid => 3}), 1, "2nd key execute");

    foreach my $first_entry (@$res){
        foreach my $second_entry (@{$first_entry->{values}}){
            foreach my $val (@{$second_entry->{values}}){
                is($firstKey->($val), $first_entry->{key}, "all values match first key");
                is($secondKey->($val), $second_entry->{key}, "all values match second key");
            }
        }
    }
};

subtest "set keyname" => sub {
    my $nest = new Data::Nest()
        ->keyname("mykey")->key("gender");
    my $res = $nest->entries(&getSample($size));

    is($nest->{keyname}, "mykey", "set keyname");
    foreach my $entry (@$res){
        foreach my $val (@{$entry->{values}}){
            is($val->{gender}, int($entry->{mykey}), "all values match key");
        }
    }
};

subtest "set valname" => sub {
    my $nest = new Data::Nest()
        ->valname("myval")->key("gender");
    my $res = $nest->entries(&getSample($size));
    is($nest->{valname}, "myval", "se valname");
    foreach my $entry (@$res){
        foreach my $val (@{$entry->{myval}}){
            is($val->{gender}, int($entry->{key}), "all values match key");
        }
    }
};

subtest "set rollup" => sub {
    my $sum = sub {
        my @data = @_;
        my $sum = 0;
        foreach my $d (@data){
            $sum += $d->{quantity};
        }
        $sum;
    };
    my $sumsq = sub {
        my @data = @_;
        my $sum = 0;
        foreach my $d (@data){
            $sum += $d->{quantity} * $d->{quantity};
        }
        $sum;
    };
    my $nest = new Data::Nest();
    $nest->key('userid')->key('itemid')
        ->rollup('sum', $sum)
        ->rollup('sumsq', $sumsq);
    my $res = $nest->entries(&getSample($size));

    is(scalar @{$nest->{rollups}}, 2, "has two roll up functions");
    is($nest->{rollups}[0]{name}, "sum", "first roll up function is sum");
    is($nest->{rollups}[1]{name}, "sumsq", "first roll up function is sumsq");

    foreach my $first_entry (@$res){
        foreach my $second_entry (@{$first_entry->{values}}){
            foreach my $val (@{$second_entry->{values}}){
                is($val->{"userid"}, $first_entry->{key}, "all values match first key");
                is($val->{"itemid"}, $second_entry->{key}, "all values match second key");

            }
            is($second_entry->{sum}, $sum->(@{$second_entry->{values}}), "`sum` is sum of sum");
            is($second_entry->{sumsq}, $sumsq->(@{$second_entry->{values}}), "`sumsq` is sum of sumsq");
        }
    }
};

subtest "set rollup no values" => sub {
    my $sum = sub {
        my @data = @_;
        my $sum = 0;
        foreach my $d (@data){
            $sum += $d->{quantity};
        }
        $sum;
    };
    my $sumsq = sub {
        my @data = @_;
        my $sum = 0;
        foreach my $d (@data){
            $sum += $d->{quantity} * $d->{quantity};
        }
        $sum;
    };
    my $nest = new Data::Nest(noValues => 1);
    $nest->key('userid')->key('itemid')
        ->rollup('sum', $sum)
        ->rollup('sumsq', $sumsq);
    my $res = $nest->entries(&getSample($size));

    is(scalar @{$nest->{rollups}}, 2, "has two roll up functions");
    is($nest->{rollups}[0]{name}, "sum", "first roll up function is sum");
    is($nest->{rollups}[1]{name}, "sumsq", "first roll up function is sumsq");

    foreach my $first_entry (@$res){
        foreach my $second_entry (@{$first_entry->{values}}){
            ok(! exists $second_entry->{values}, "no values");
        }
    }
};

done_testing;

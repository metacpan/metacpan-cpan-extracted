# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Algorithm::Graphs::TransitiveClosure qw /floyd_warshall/;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $test_num = 2;

eval {
    my $graph = [
        [1, 0, 0, 0],
        [0, 1, 1, 1],
        [0, 1, 1, 0],
        [1, 0, 1, 1],
    ];
    floyd_warshall $graph;
    if ("@{$graph->[0]}" eq '1 0 0 0' and
        "@{$graph->[1]}" eq '1 1 1 1' and
        "@{$graph->[2]}" eq '1 1 1 1' and
        "@{$graph->[3]}" eq '1 1 1 1') {
        print "ok ", $test_num ++, "\n";
    }
    else {
        print "not ok ", $test_num ++, "\n";
    }
};

if ($@) {print "... error: $@\n";}

eval {
    my $graph = {
        one   => {one => 1},
        two   => {two => 1, three => 1, four => 1},
        three => {two => 1, three => 1},
        four  => {one => 1, three => 1, four => 1},
    };
    floyd_warshall $graph;
    if (1 == keys %{$graph -> {one}}   && $graph -> {one}   -> {one}   == 1 &&
        4 == keys %{$graph -> {two}}   && $graph -> {two}   -> {one}   == 1 &&
                                          $graph -> {two}   -> {two}   == 1 &&
                                          $graph -> {two}   -> {three} == 1 &&
                                          $graph -> {two}   -> {four}  == 1 &&
        4 == keys %{$graph -> {three}} && $graph -> {three} -> {one}   == 1 &&
                                          $graph -> {three} -> {two}   == 1 &&
                                          $graph -> {three} -> {three} == 1 &&
                                          $graph -> {three} -> {four}  == 1 &&
        4 == keys %{$graph -> {four}}  && $graph -> {four}  -> {one}   == 1 &&
                                          $graph -> {four}  -> {two}   == 1 &&
                                          $graph -> {four}  -> {three} == 1 &&
                                          $graph -> {four}  -> {four}  == 1) {
        print "ok ", $test_num ++, "\n";
    }
    else {
        print "not ok ", $test_num ++, "\n";
    }
};

if ($@) {print "... error: $@\n";}


#!perl -w
use Test::More;
eval q{use Test::Pod::Coverage 1.04};
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage'
    if $@;

all_pod_coverage_ok({
    also_private => [
        qw(unimport BUILD DEMOLISH init_meta),
        qw/
default_max_workers
dequeue
enqueue
finish
init
is_child
is_working_max
num_queues
num_workers
/
        ],
});

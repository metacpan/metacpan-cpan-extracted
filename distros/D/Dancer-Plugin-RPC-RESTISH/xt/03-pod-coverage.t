#! perl -w
use strict;

{
    no warnings 'redefine';
    sub Pod::Coverage::TRACE_ALL () {1}
    sub Pod::Coverage::debug () {1}
}
use Test::Pod::Coverage;

all_pod_coverage_ok();

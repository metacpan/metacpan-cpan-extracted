#!perl -T

use Test::More tests => 1;
use Combinator;

my @job_stack;

sub compute {
    $_[1]($_[0]);
}

my @out;
{{com
    push @out, 1;

    unshift @job_stack, {{nex compute(3, {{nex $out[0]=$_[0]}}nex) }}nex;
    unshift @job_stack, {{nex compute(4, {{nex $out[1]=$_[0]}}nex) }}nex;
    unshift @job_stack, {{nex compute(1, {{nex $out[2]=$_[0]}}nex) }}nex;
    unshift @job_stack, {{nex compute(2, {{nex $out[3]=$_[0]}}nex) }}nex;

    $_->() for(@job_stack);
  --ser
    is_deeply(\@out, [3,4,1,2], "nex_block");
}}com

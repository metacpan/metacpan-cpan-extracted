#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('B::CompilerPhase::Hook', qw[
       enqueue_BEGIN
       append_BEGIN
       prepend_BEGIN
    ]);

    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_BEGIN_array() }), 0, '... BEGIN never has any more');
}

=pod

The thing about BEGIN blocks is that they
happen so early in the compile phase that
you will almost always just encounter an
empty array. This is because the we removed
the currently running block before we
executed, and the remainder of the file has
not yet been parsed so there are no future
scheduled BEGIN blocks.

This means that whether you enqueue, append,
or prepend onto the BEGIN block queue, it
basically will have the exact same result.
This is because they are all acting on the
same empty array.

=cut

our @TEST;

BEGIN {
    #diag '1';
    is(scalar(@TEST), 0, '... got the undefined TEST');
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_BEGIN_array() }), 0, '... BEGIN never has any more');
    enqueue_BEGIN { push @TEST => 2 };
    prepend_BEGIN { push @TEST => 1 };
    append_BEGIN  { push @TEST => 3 };
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_BEGIN_array() }), 3, '... BEGIN now has three, which will run immediately afterwards');
    is(scalar(@TEST), 0, '... (still) got the undefined TEST');
}
BEGIN {
    #diag '3';
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_BEGIN_array() }), 0, '... BEGIN never has any more');
    is(scalar(@TEST), 3, '... got the expected true value of TEST');
    is_deeply(\@TEST, [1, 2, 3], '... got the right values as well');
}

done_testing();


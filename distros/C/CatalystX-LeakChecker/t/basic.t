use strict;
use warnings;
use Test::More;
use B::Deparse;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

{
    my ($resp, $ctx) = ctx_request('/affe/no_closure');
    is($resp->content, 'no_closure');
    is($ctx->count_leaks, 0, 'no leaks reported without stashed closures');
}

{
    my ($resp, $ctx) = ctx_request('/affe/leak_closure');
    is($resp->content, 'leak_closure');
    is($ctx->count_leaks, 1, 'one leak reported with a stashed closure, closing over $ctx');

    my $leak = $ctx->first_leak;
#    is($leak->{var}, '$ctx', 'right variable name reported for closed over context');
#    like(
#        B::Deparse->new->coderef2text($leak->{code}),
#        qr/leaky closure/,
#        'right code reference reported for leaky closure',
#    );
}

{
    my ($resp, $ctx) = ctx_request('/affe/weak_closure');
    is($resp->content, 'weak_closure');
    is($ctx->count_leaks, 0, 'no leak reported with a stashed closure, closing over a weak $ctx');
}

{
    my ($resp, $ctx) = ctx_request('/affe/leak_closure_indirect');
    is($resp->content, 'leak_closure_indirect');
    is($ctx->count_leaks, 1, 'one leak reported with stashed closure, closing over something with a reference to $ctx');
}

{
    my ($resp, $ctx) = ctx_request('/affe/weak_closure_indirect');
    is($resp->content, 'weak_closure_indirect');
    is($ctx->count_leaks, 0, 'no leak when closing over something holding a weak reference to $ctx');
}

{
    my ($resp, $ctx) = ctx_request('/affe/stashed_ctx');
    is($resp->content, 'stashed_ctx');
    is($ctx->count_leaks, 1, 'one leak found when stashing $ctx');
}

{
    my ($resp, $ctx) = ctx_request('/affe/stashed_weak_ctx');
    is($resp->content, 'stashed_weak_ctx');
    is($ctx->count_leaks, 0, 'no leak when stashing a weak $ctx');
}

done_testing;

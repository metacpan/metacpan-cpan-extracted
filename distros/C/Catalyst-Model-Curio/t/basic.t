#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

use FindBin '$Bin';
use lib "$Bin/lib";
use Catalyst::Test 'MyApp';

subtest no_keys => sub{
    my $set_content = get('/single_set/foo/bar');
    is( $set_content, 'Cache value set', 'set says it worked' );

    my $get_content = get('/single_get/foo');
    is( $get_content, 'bar', 'get returned the setted value' );
};

subtest set_key => sub{
    my $set_content = get('/keyed_set/foo/bar');
    is( $set_content, 'Cache value set', 'set says it worked' );

    my $get_content = get('/keyed_get/foo');
    is( $get_content, 'bar', 'get returned the setted value' );
};

subtest multi_keys => sub{
    my $set1_content = get('/multi_set/test_one/foo/bar');
    is( $set1_content, 'Cache value set', 'set says it worked' );

    my $get1_content = get('/multi_get/test_one/foo');
    is( $get1_content, 'bar', 'get returned the setted value' );

    my $get2_content = get('/multi_get/test_two/foo');
    is( $get2_content, '', 'get returned empty value' );

    my $get3_res = request('/multi_get/test_three/foo');
    is( $get3_res->code(), 500, 'failed using undeclared curio key' );
};

subtest default_key => sub{
    my $set_content = get('/default_set/foo/bar');
    is( $set_content, 'Cache value set', 'set says it worked' );

    my $get_content = get('/default_get/foo');
    is( $get_content, 'bar', 'get returned the setted value' );
};

done_testing;

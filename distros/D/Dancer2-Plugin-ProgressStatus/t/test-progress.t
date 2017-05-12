#!/usr/bin/env perl

package My::Dancer2::App;
use strict;
use warnings;

use File::Spec;
use File::Temp;
use YAML qw/DumpFile/;

my $dir;
## Create config settings required by plugin
BEGIN {
    $dir = File::Temp->newdir(CLEANUP => 0);
    my $file = File::Spec->catfile($dir, 'config.yml');
    DumpFile($file, { plugins => { ProgressStatus => { dir => "$dir" }}});

    $ENV{DANCER_CONFDIR} = "$dir/";
};

use Dancer2;
use Dancer2::Plugin::ProgressStatus;

get '/test_progress_status_simple_with_no_args' => sub {
    my $prog = start_progress_status('test');
    $prog++;
    $prog++; # count should be 2

    return 'ok';
};

get '/test_progress_status_with_args' => sub {
    my $prog = start_progress_status({
        name     => 'test2',
        total    => 200,
        count    => 0,
    });

    $prog++;
    $prog++;
    $prog++;
    $prog->add_message('Message1');
    $prog->add_message('Message2');
    # count should be 3 and messages should be size 2

    return 'ok';
};

get '/test_progress_status_good_concurrency' => sub {
    my $prog1 = start_progress_status({
        name    => 'test3',
        total   => 200,
    });
    my $prog2 = eval { start_progress_status('test3') }; # This should die

    if ( $@ ) {
        return $@;
    }

    return 'ok';
};

# Test progress status with an extra identifier
get '/test_progress_with_progress_id' => sub {
    my $prog = start_progress_status();

    return 'ok';
};

package main;
use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common;
use JSON;
use Test::More;
use Test::Warnings;

my $app  = Plack::Test->create(Dancer2->psgi_app);
my $json = JSON->new->utf8(0);

############################################################################
## Test a simple progress bar

{
    my $response1 = $app->request( GET '/test_progress_status_simple_with_no_args' );
    ok( $response1->is_success, 'Response ok when setting and updating progress' );

    my $response2 = $app->request( GET '/_progress_status/test' );
    ok($response2->is_success, 'Get good response from progressstatus');

    my $data = $json->decode($response2->decoded_content);
    is($data->{total}, 100, 'Total is 100');
    is($data->{count}, 2, 'Count matches total');
    ok(!$data->{in_progress}, 'No longer in progress');
}

############################################################################
## Test a progress bar with args

{
    my $response1 = $app->request( GET '/test_progress_status_with_args' );
    ok( $response1->is_success, 'Success for less simple progress' );

    my $response2 = $app->request( GET '/_progress_status/test2' );
    my $data = $json->decode($response2->decoded_content);
    is($data->{total}, 200, 'Total is 200');
    is($data->{count}, 3, 'Count matches total');
    is(scalar(@{$data->{messages}}), 2, 'Has two messages');
    ok(!$data->{in_progress}, 'No longer in progress');
}


############################################################################
## Concurrency tests
{
    my $response1 = $app->request( GET '/test_progress_status_good_concurrency' );
    ok($response1->is_success, 'Two progress meters with the same name and same pid pass');
    like($response1->content, qr/^Progress status test3 already exists/,
        'two unfinished progress meters with the same name dies');

    my $response2 = $app->request( GET '/_progress_status/test3' );
    my $data = $json->decode($response2->decoded_content);
    is($data->{total}, 200, 'Total is overriden');
}

{
    ## Test progress status with automatic ID
    my $response1 = $app->request(GET '/test_progress_with_progress_id?progress_id=1000');
    ok($response1->is_success, '200 response for progress with progress id');

    my $response2 = $app->request(GET '/_progress_status/1000');
    ok($response2->is_success, 'Get good response from progressstatus');
    my $data = $json->decode($response2->decoded_content);
    is($data->{total}, 100, 'Get a sensible response');
}


done_testing(17); # number of tests + Test::Warnings

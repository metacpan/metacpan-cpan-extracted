#!perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Data::Dump;
use Test::More;

SKIP: {
    eval { require Test::WWW::Mechanize::Catalyst };
    skip "Skipping dispatch tests without Mechanize", 2 if $@;

    my $c = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');

    my $content = $c->get_ok('/create');
    $c->content_contains('did not create message', 'Correct body for GET /create');
    $content = $c->get_ok('/read');
    $c->content_contains('no messages', 'Correct body for GET /read before POST');

    $content = $c->post('/create', { message => 'This is a message from a POST, inside the unit test' });
    $c->content_contains('This is a message from a POST, inside the unit test');

    $content = $c->post('/create', {
        message => 'This is a message from a POST, for the multiple method',
        multiple => 1
    });
    $c->content_contains('This is a message from a POST, for the multiple methodAn additional message from the multiple method');

    $content = $c->post('/tweak_config', {
        key => 'stash_key',
        value => 'msgs'
    });
    $c->content_contains('{ stash_key => "msgs" }');

    $content = $c->post('/create', { message => 'This is a message from a POST with a custom stash_key' });
    $c->content_contains('This is a message from a POST with a custom stash_key');


    $content = $c->post('/tweak_config', {
        key => 'flash_key',
        value => '_msgs'
    });
    $c->content_contains('{ flash_key => "_msgs", stash_key => "msgs" }');

    $content = $c->post('/create', { message => 'This is a message from a POST with a custom stash_key and flash_key' });
    $c->content_contains('This is a message from a POST with a custom stash_key and flash_key');


    $content = $c->post('/tweak_config', {
        key => 'results_flash_key',
        value => '_res'
    });
    $c->content_contains('{ flash_key => "_msgs", results_flash_key => "_res", stash_key => "msgs" }');

    $content = $c->post('/create', { message => 'This is a message from a POST with a custom stash_key, flash_key, and results_flash_key' });
    $c->content_contains('This is a message from a POST with a custom stash_key, flash_key, and results_flash_key');
 
    $content = $c->post('/tweak_config', {
        key => 'results_stash_key',
        value => 'res'
    });
    $c->content_contains("{\n  flash_key => \"_msgs\",\n  results_flash_key => \"_res\",\n  results_stash_key => \"res\",\n  stash_key => \"msgs\",\n}");

    $content = $c->post('/create', { message => 'This is a message from a POST with a custom stash_key, flash_key, results_stash_key, and results_flash_key' });
    $c->content_contains('This is a message from a POST with a custom stash_key, flash_key, results_stash_key, and results_flash_key');
 

    $content = $c->get_ok('/redirect_source');
    $c->content_contains('multiple redirects preserve messages', 'Correct body for GET /read after redirects');

   
}

done_testing;

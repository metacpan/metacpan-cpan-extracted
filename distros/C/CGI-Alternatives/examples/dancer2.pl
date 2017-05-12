#!/usr/bin/env perl

# automatically enables strict and warnings
use Dancer2;
 
any [ 'get','post' ] => '/example_form' => sub {

    template 'example_form.html.tt', {
        'result' => params->{'user_input'}
    };
};
 
start;

#!/usr/bin/perl
 
use strict;
use warnings;
 
use File::Temp;
use File::Spec;
 
use Catalyst::Plugin::Session::Test::Store (
    backend => 'Redis::Fast',
    config => { server => $ENV{SESSION_STORE_REDIS_URL} },
    extra_tests => 1
);
 
{
    package SessionStoreTest;
    use Catalyst;

    sub store_scalar : Global {
        my ($self, $c) = @_;
 
        $c->res->body($c->session->{'scalar'} = 786);
    }

    sub get_scalar : Global {
        my ($self, $c) = @_;
 
        $c->res->body($c->session->{'scalar'});
    }
 
    __PACKAGE__->setup_actions;
 
}

1;
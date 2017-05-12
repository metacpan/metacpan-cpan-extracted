#!/usr/bin/perl -w
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

use Ambrosia::Context;
instance Ambrosia::Context( engine_name => 'CGI', engine_params => {} );
Context->start_session();

use Ambrosia::BaseManager;


my %conf = (
    base => {
            manager => 't::BaseManager',
            access   => 0,
        },
    forward => {
            manager => 't::ForwardManager',
            access   => 0,
        },
    forward_base => {
            manager => 't::ForwardBaseManager',
            access   => 0,
        },
    relegate => {
            manager => 't::RelegateManager',
            access   => 0,
        },
);

local $ENV{TEST_BASE_MANAGER} = [];
controller( __managers => \%conf );

my $NUM_ITER = 100_000;
timethese($NUM_ITER, {
    'relegate' => sub {
            $ENV{TEST_BASE_MANAGER} = [];
            controller->relegate('relegate');
            controller->next_manager->process;
            controller->next_manager->process;
        },
});

timethese($NUM_ITER, {
    'relegate2' => sub {
            $ENV{TEST_BASE_MANAGER} = [];
            controller->relegate('relegate');
            for(; controller->next_manager->process; ){};
        },
});


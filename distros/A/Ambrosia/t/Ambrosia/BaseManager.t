#!/usr/bin/perl
use Test::More tests => 8;
#use Test::Exception;
use Test::Deep;
use lib qw(lib t ..);
use Carp;

use Data::Dumper;

BEGIN {
    use_ok( 'Ambrosia::BaseManager' ); #test #1
}

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

controller->relegate($conf{base});
controller->next_manager->process;
ok($ENV{TEST_BASE_MANAGER}->[0] eq 'base', 'process base manager #1'); #test #2

$ENV{TEST_BASE_MANAGER} = [];
controller->relegate('base');
controller->next_manager->process;
ok($ENV{TEST_BASE_MANAGER}->[0] eq 'base', 'process base manager #2'); #test #3

$ENV{TEST_BASE_MANAGER} = [];
controller->relegate('relegate');
controller->next_manager->process;
ok($ENV{TEST_BASE_MANAGER}->[0] eq 'relegate', 'process relegate main manager'); #test #4
controller->next_manager->process;
cmp_deeply($ENV{TEST_BASE_MANAGER}, ['relegate', 'base'], 'process relegate next manager'); #test #5

$ENV{TEST_BASE_MANAGER} = [];
controller->relegate('forward');
controller->next_manager->process;
#print Dumper(Context);
ok($ENV{TEST_BASE_MANAGER}->[0] eq 'forward', 'process forward main manager'); #test #6
controller->next_manager->process;
#print Dumper(Context);
cmp_deeply($ENV{TEST_BASE_MANAGER}, ['forward', 'forward_base'], 'process forward next manager #1'); #test #7
controller->next_manager->process;
#print Dumper(Context);
cmp_deeply($ENV{TEST_BASE_MANAGER}, ['forward', 'forward_base', 'base'], 'process forward next manager #2'); #test #8

Context->finish_session();

package MyApp;

use strict;
use warnings;

use Test2::V0;

plan 8;

use Dancer2;
use Test::WWW::Mechanize::PSGI;

set template => 'Caribou';

my $mech = Test::WWW::Mechanize::PSGI->new(
    app => MyApp->to_app,
);

get '/hi/:name' => sub {
    template 'welcome' => { name => route_parameters->get('name') };
};

$mech->get_ok( '/hi/yanick' );
$mech->content_contains( 'hello yanick' );

get '/howdie/:name' => sub {
    template 'howdie' => { name => param('name') };
};

$mech->get_ok( '/howdie/yanick' );
$mech->content_contains( 'howdie yanick' );

get '/hullo/:name' => sub {
    
    set layout => 'main';
    template 'hullo' => { name => param('name') };
};

get '/dancer_variables' => sub { 
    template 'dancer_variables';
};

$mech->get_ok( '/hullo/yanick' );
$mech->content_contains( 'hullo yanick' );

$mech->get_ok( '/dancer_variables' );
$mech->content_contains( 'foo' );

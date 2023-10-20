package MyApp;

use strict;
use warnings;

use Test2::V0; plan 2;

use Dancer2;
use Test::WWW::Mechanize::PSGI;

{ 
    package Dancer2::View::MyView;

    use Template::Caribou;

    template page => sub {
        "hello world";
    };

}

setting template => 'Caribou';

get '/' => sub { template 'MyView' };


my $mech = Test::WWW::Mechanize::PSGI->new(
    app => MyApp->to_app 
);
$mech->get_ok('/');
$mech->content_contains('hello world');

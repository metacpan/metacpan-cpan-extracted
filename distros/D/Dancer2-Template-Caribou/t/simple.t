package MyApp;

use strict;
use warnings;

use Test::More tests => 1;

use Dancer2;
use Dancer2::Test;


{ 
    package Dancer2::View::MyView;

    use Template::Caribou;

    template page => sub {
        "hello world";
    };

}

setting template => 'Caribou';

get '/' => sub { template 'MyView' };


response_content_is '/' => 'hello world';

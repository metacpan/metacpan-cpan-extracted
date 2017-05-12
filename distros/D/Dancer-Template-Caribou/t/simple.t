package MyApp;

use strict;
use warnings;

use Test::More tests => 1;

use Dancer '!pass';
use Dancer::Test;


{ 
    package Dancer::View::MyView;

    use Template::Caribou;

    template page => sub {
        "hello world";
    };

}

setting template => 'Caribou';
setting warnings => 1;
setting show_errors => 1;
setting log => 'console';

get '/' => sub { template 'MyView' };


response_content_is '/' => 'hello world';

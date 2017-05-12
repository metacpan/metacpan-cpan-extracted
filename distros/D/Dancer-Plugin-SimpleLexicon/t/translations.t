#!perl

use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec::Functions qw/catfile catdir/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Dancer ':tests';
use Dancer::Plugin::SimpleLexicon;
use Dancer::Test;

set plugins => {
                'SimpleLexicon' => {
                                    'var_name' => 'lang',
                                    'default' => 'en',
                                    'langs' => { 
                                                'it' => 'Italiano',
                                                'en' => 'US English',
                                                'se' => 'Sweden'
                                               },
                                    'session_name' => 'lang',
                                    'param_name' => 'lang',
                                    'path' => catdir('t' ,'languages'),
                                   },
               };

set session => 'Simple';
set logger  => "console";


get "/test/:lang" => sub {
    return l('Please select');
};

get "/moretest/:lang" => sub {
    return l('Select %s', "string");
};

plan tests => 11;

var lang => 'en';
is(language, 'US English');

var lang => 'se';
is(language, 'Sweden');

response_content_is [ GET => '/test/it' ], 'Scegli un’opzione';
response_content_is [ GET => '/test/blabla' ], 'Please select';
response_content_is [ GET => '/test/se' ], 'Välj';
response_content_is [ GET => '/test/en' ], 'Please select an option';

response_content_is [ GET => '/moretest/it' ], 'Scegli un’opzione string';
response_content_is [ GET => '/moretest/blabla' ], 'Select string';
response_content_is [ GET => '/moretest/se' ], 'Välj string';
response_content_is [ GET => '/moretest/en' ], 'Please select string option';

set_language('it');

is(session('lang'), 'it');


#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Data::Dumper;

use Dancer qw/:syntax/;

set template => 'template_flute';
set views => 't/views';
set log => 'debug';


get '/' => sub {
    session salute => "Hello world!";
    template salute => {};
};

use Test::More tests => 2, import => ['!pass'];

use Dancer::Test;

response_status_is [GET => '/'], 200, "GET / is found";
response_content_like [GET => '/'], qr{Hello world}, "GET / ok";
print to_dumper(read_logs);

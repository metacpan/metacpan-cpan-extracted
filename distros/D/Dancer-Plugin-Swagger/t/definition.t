package TestMe;

use strict;
use warnings;

use  Test::WWW::Mechanize::PSGI;

use Test::More tests => 2;
use Test::Deep;


use Dancer ':tests';

use Dancer::Plugin::Swagger;

set serializer => 'JSON';
Dancer::Plugin::Swagger->instance->{main_api_module_content} = '';

$::mech = Test::WWW::Mechanize::PSGI->new( app => Dancer::Handler->psgi_app );

sub swagger_path_test {
    my $name = shift;
    my $test = pop;
    my $args = shift;
    subtest $name => sub {
        swagger_path $args, get $name, sub { $test->() };
        $::mech->get_ok( $name );
    };
}

my $Judge = swagger_definition 'Judge' => {
    type => 'object',
    required => [ 'fullname' ],
    properties => {
        fullname => { type => 'string' },
        seasons => { type => 'array', items => { type => 'integer' } },
    }
};

cmp_deeply $Judge => { '$ref' => '#/definitions/Judge' }, 
    "swagger_definition returns shortcut";

swagger_path_test '/definitions' => {
    responses => {
        default => { schema => $Judge },
    },
}, sub {
    cmp_deeply $Dancer::Plugin::Swagger::THIS_ACTION->responses, {
        default => { schema => $Judge },
    };
};

TestMe::dance if @ARGV and shift eq 'RUN';

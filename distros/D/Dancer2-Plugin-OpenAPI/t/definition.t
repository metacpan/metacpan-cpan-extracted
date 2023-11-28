package TestMe;

use strict;
use warnings;

use  Test::WWW::Mechanize::PSGI;

use Test::More tests => 2;
use Test::Deep;


use Dancer2;

use Dancer2::Plugin::OpenAPI;

set serializer => 'JSON';

my $app = TestMe->to_app;
$::mech = Test::WWW::Mechanize::PSGI->new( app => $app );

sub openapi_path_test {
    my $name = shift;
    my $test = pop;
    my $args = shift;
    subtest $name => sub {
        openapi_path $args, get $name, sub { $test->() };
        $::mech->get_ok( $name );
    };
}

my $Judge = openapi_definition 'Judge' => {
    type => 'object',
    required => [ 'fullname' ],
    properties => {
        fullname => { type => 'string' },
        seasons => { type => 'array', items => { type => 'integer' } },
    }
};

cmp_deeply $Judge => { '$ref' => '#/definitions/Judge' }, 
    "openapi_definition returns shortcut";

openapi_path_test '/definitions' => {
    responses => {
        default => { schema => $Judge },
    },
}, sub {
    cmp_deeply $Dancer2::Plugin::OpenAPI::THIS_ACTION->responses, {
        default => { schema => $Judge },
    };
};

TestMe::dance if @ARGV and shift eq 'RUN';

use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan skip_all => "JSON is needed for this test"
  unless Dancer::ModuleLoader->load('JSON');
plan skip_all => "YAML is needed for this test"
  unless Dancer::ModuleLoader->load('YAML');

my $data = { foo => 42 };
my $json = JSON::encode_json($data);
my $yaml = YAML::Dump($data);

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;

    set environment => 'test';
    set show_errors => 1;

    prepare_serializer_for_format;

    get '/' => sub { "root" };
    get '/:something.:format' => sub {
        $data;
    };
}

use Dancer::Test;

my @tests = (
    {
        request  => [ GET => '/' ],
        response => 'root',
    },
    {
        request  => [ GET => '/foo.json' ],
        response => $json,
    },
    {
        request  => [ GET => '/foo.yml' ],
        response => $yaml,
    },
    {
        request  => [ GET => '/' ],
        response => 'root',
    },
);

plan tests => 6;

for my $test (@tests) {
    my $response = dancer_response( @{ $test->{request} } );
    if ( ref( $test->{response} ) ) {
        like( $response->{content}, $test->{response},
            "response looks good for '@{$test->{request}}'" );
    }
    else {
        is( $response->{content}, $test->{response},
            "response looks good for '@{$test->{request}}'" );
    }
}

my $response = dancer_response( GET => '/foo.foobar' );

is $response->status => 404, 'error code 404';
like $response->content => qr/unsupported format requested: foobar/ms;

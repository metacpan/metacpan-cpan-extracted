use strict;
use warnings;
use Module::Runtime qw(use_module);
use Test::More import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;

plan skip_all => "JSON is needed for this test"
    unless use_module('JSON');
plan skip_all => "YAML is needed for this test"
    unless use_module('YAML');

my $data = { foo => 42 };
my $json = JSON::encode_json($data);
my $yaml = YAML::Dump($data);

{
    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::REST;

    prepare_serializer_for_format;

    set environment => 'test';

    get '/' => sub { "root" };
    get '/:something.:format' => sub {
        $data;
    };
}

my $plack_test = Plack::Test->create(Webservice->to_app);

my @tests = (
    {
        path => '/',
        response => 'root',
    },
    {
        path => '/foo.json',
        response => $json,
    },
    {
        path => '/foo.yml',
        response => $yaml,
    },
    {
        # doing it a second time to make sure we don't have a lingering
        # serializer
        path => '/',
        response => 'root',
    },
);

plan tests => scalar(@tests);

for my $test ( @tests ) {
    subtest $test->{path} => sub { 
        my $response = $plack_test->request( GET $test->{path} );

        if (ref($test->{response})) {
            like( $response->content, $test->{response},
                "response looks good for 'GET $test->{path}'" );
        }
        else {
            is( $response->content, $test->{response},
                "response looks good for 'GET $test->{path}'" );
        }
    };
}




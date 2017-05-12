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

    setting environment => 'testing';

    prepare_serializer_for_format;

    get '/' => sub { "root" };
    get qr{ ^ / (?<something> \w+) \. (?<format> \w+) }x => sub {
        $data;
    };
}

my $plack_test = Plack::Test->create( Webservice->to_app );

my @tests = (
    {
        path => '/',
        content_type => qr'text/html',
        response => 'root',
    },
    {
        path => '/foo.json',
        content_type => qr'application/json',
        response => $json
    },
    {
        path => '/foo.yml',
        content_type => qr'text/x-yaml',
        response => $yaml,
    },
    {
        path => '/',
        content_type => qr'text/html',
        response => 'root',
    },
);

plan tests => scalar @tests;

for my $test ( @tests ) {
    subtest $test->{path} => sub {
        my $response = $plack_test->request( GET $test->{path} );

        like($response->header('Content-Type'),
        $test->{content_type},
        "headers have content_type set to ".$test->{content_type});

        is( $response->content, $test->{response},
            "\$data has been encoded" );
    };
}

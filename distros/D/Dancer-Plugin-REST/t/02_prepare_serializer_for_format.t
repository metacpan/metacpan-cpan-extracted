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
    use Dancer::Plugin::REST;

    setting environment => 'testing';

    prepare_serializer_for_format;

    get '/' => sub { "root" };
    get '/:something.:format' => sub {
        $data;
    };
}
use Dancer::Test;

my @tests = (
    {
        request => [GET => '/'],
        content_type => 'text/html',
        response => 'root',
    },
    { 
        request => [GET => '/foo.json'],
        content_type => 'application/json',
        response => $json
    },
    { 
        request => [GET => '/foo.yml'],
        content_type => 'text/x-yaml',
        response => $yaml,
    },
    {
        request => [GET => '/'],
        content_type => 'text/html',
        response => 'root',
    },
);

plan tests => scalar(@tests) * 2;

for my $test ( @tests ) {
    my $response = dancer_response(@{ $test->{request} });
    is($response->header('Content-Type'), 
       $test->{content_type},
       "headers have content_type set to ".$test->{content_type});

    is( $response->{content}, $test->{response},
        "\$data has been encoded" );
}

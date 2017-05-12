use strict;
use warnings;

{
    package Foo;

    use Dancer;
    use Dancer::Plugin::REST;

    prepare_serializer_for_format;

    post '/foo.:format' => sub {
        return params;
    };

}

use Test::More;
use Dancer::ModuleLoader;

plan skip_all => 'tests require JSON' 
    unless Dancer::ModuleLoader->load('JSON');

plan tests => 2;

use Dancer::Test;
use HTTP::Headers;

my $head = HTTP::Headers->new;

$head->header("content-type" => "application/json");

for ( 1..2 ) {
    my $resp = dancer_response( 'POST' => '/foo.json', {
            body => '{"yin":"yang","foo":"bar"}',
            headers => $head,
    });

    like $resp->content, qr/yin/;
}

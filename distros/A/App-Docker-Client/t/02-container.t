#!perl -T
use 5.16.0;
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($Bin);

use App::Docker::Client;

plan tests => 7;

#client preparings based on local test datas
my $test_container = File::Spec->catfile( $Bin, 'data' );
my $client = new_ok(
    'App::Docker::Client' => [
        'UserAgent', LWP::UserAgent->new(),
        'scheme',    'file',
        'authority', $test_container
    ]
);

isa_ok $client, 'App::Docker::Client';
isa_ok $client->user_agent, 'LWP::UserAgent';
is $client->scheme,         'file';
is $client->authority,      $test_container;

# test like inspect container
my $cont = $client->get( File::Spec->catfile( 'containers', 'test', 'json' ) );
is( $cont->{Name}, "/Test" );
is( $cont->{Id},
    "a1dbb1a58c0dd76a463b1ec1e505071563f3a7c72d1a22627b6f31334ae6412f" );
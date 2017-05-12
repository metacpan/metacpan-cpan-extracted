package TestApp;

use strict;
use warnings;

use lib 't';

use Dancer qw/:syntax :tests/;
use Dancer::Plugin::Cache::CHI;

use Dancer::Test;
use Test::More;

eval {
    require File::Temp;
    require CHI::Driver::FastMmap;
    1;
} or plan skip_all =>
'File::Temp and CHI::Driver::FastMmap required for these tests' . " ($@)";

File::Temp->import( 'tempdir' );

set plugins => {
    'Cache::CHI' => {
        driver => 'FastMmap',
        global => 1,
        expires_in => '100 min',
        root_dir => tempdir( CLEANUP => 1 ),
    },
};

setting show_errors => 1;

for ( qw/ foo bar / ) {
    my $cache = cache $_;

    get "/$_/*" => sub { $cache->set( x => splat ); 1; };
    get "/$_" => sub { $cache->get( "x" ) };
}

plan tests => 4;

response_status_is "/foo/monkey" => 200, "storing monkey";
response_status_is "/bar/walrus" => 200, "storing walrus";

response_content_is '/foo', 'monkey';
response_content_is '/bar', 'walrus';

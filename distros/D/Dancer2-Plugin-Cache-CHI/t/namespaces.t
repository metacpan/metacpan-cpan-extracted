use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

eval {
    require File::Temp;
    require CHI::Driver::FastMmap;
};
if ($@) {
    plan skip_all =>
        "File::Temp and CHI::Driver::FastMmap required for these tests ($@)";
}

{
    package TestApp;

    use Dancer2;
    use Dancer2::Plugin::Cache::CHI;
    eval {
        require File::Temp;
        require CHI::Driver::FastMmap;
    };

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

}

plan tests => 5;

my $app = Dancer2->runner->psgi_app;
is ref $app, 'CODE', 'got app';

test_psgi $app, sub {
    my $cb  = shift;

    is $cb->(GET "/foo/monkey")->code, 200, "storing monkey";
    is $cb->(GET "/bar/walrus")->code, 200, "storing walrus";

    is $cb->(GET '/foo')->content, 'monkey', 'get monkey';
    is $cb->(GET '/bar')->content, 'walrus', 'get walrus';
}

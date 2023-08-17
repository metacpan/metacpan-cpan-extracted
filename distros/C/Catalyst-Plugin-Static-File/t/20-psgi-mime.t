#!perl

use Test::Most;

use Plack::Builder;
use Plack::MIME;
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';
use App;

Plack::MIME->add_type( ".txt" => "text/foobar" );

my $app = builder {
    App->psgi_app;
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

$mech->get_ok( '/?file=hello.txt' );
is $mech->ct, "text/foobar";

done_testing;

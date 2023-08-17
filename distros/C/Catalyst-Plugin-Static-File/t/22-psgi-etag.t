#!perl

use Test::Most;

eval "use Plack::Middleware::ETag;";
plan skip_all => "Plack::Middleware::ETag is not installed" if $@;

use FindBin qw/ $Bin /;
use Path::Tiny;
use Plack::Builder;
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';
use App;

Plack::MIME->add_type( ".txt" => "text/foobar" );

my $app = builder {
    enable "ETag";
    App->psgi_app;
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

my $file = path($Bin)->child("static/hello.txt");

my $res = $mech->get( '/?file=' . $file->basename );
is $res->code, 200, 'GET /?file=hello.txt';

note my $etag = $res->header('ETag');
ok $etag, 'ETag';


done_testing;

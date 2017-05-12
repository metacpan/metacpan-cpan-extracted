# $Id: 01-client.t 1077 2006-01-04 06:59:42Z btrott $

use strict;
use FindBin qw( $Bin );
use lib "$Bin/lib";

use Test::More tests => 18;
use TestApp;
use Catalyst::Test 'TestApp';
use XML::Atom::Client;
use XML::Atom::Entry;
use XML::Atom::Feed;

sub req_auth_err {
    my($req_sub, $client_sub, $code) = @_;
    my $req = $req_sub->();
    my $client = $client_sub->();
    $client->munge_request($req);
    my $res = request($req);
    like $res->content, qr/Unauthenticated/;
    ok $res->header('WWW-Authenticate');
    like $res->header('WWW-Authenticate'), qr/Basic/;
    like $res->header('WWW-Authenticate'), qr/WSSE/;
    is $res->code, $code;
}

sub req_ok {
    my($req_sub, $client_sub, $regex) = @_;
    my $req = $req_sub->();
    my $client = $client_sub->();
    $client->munge_request($req);
    my $res = request($req);
    like $res->content, qr/Blog/;
}

req_auth_err \&req_get, \&client_noauth, 401;
req_auth_err \&req_get, \&client_badauth, 403;
req_ok \&req_get, \&client_good;

my($req, $res, $xml);

$req = req_get();
client_good()->munge_request($req);
$xml = get $req;
my $feed = XML::Atom::Feed->new(\$xml);
isa_ok $feed, 'XML::Atom::Feed';
is $feed->title, 'Blog';
my @links = $feed->link;
is scalar(@links), 1;
is $links[0]->href, 'http://btrott.typepad.com/typepad/';

my $entry = XML::Atom::Entry->new;
$entry->title('Foo');
$req = req_post($entry->as_xml);
client_good()->munge_request($req);
$res = request $req;
is $res->code, 201;
my $entry2 = XML::Atom::Entry->new( \$res->content );
isa_ok $entry2, 'XML::Atom::Entry';
is $entry2->title, 'Bar';

sub req_get { HTTP::Request->new( GET => '/' ) }

sub req_post {
    my $req = HTTP::Request->new( POST => '/' );
    $req->content_type('application/x.atom+xml');
    my $xml = $_[0];
    $req->content_length(length $xml);
    $req->content($xml);
    $req;
}

sub client_good {
    my $client = XML::Atom::Client->new;
    $client->username('foo');
    $client->password('bar');
    $client;
}

sub client_noauth { XML::Atom::Client->new }

sub client_badauth {
    my $client = XML::Atom::Client->new;
    $client->username('foo');
    $client->password('baz');
    $client;
}

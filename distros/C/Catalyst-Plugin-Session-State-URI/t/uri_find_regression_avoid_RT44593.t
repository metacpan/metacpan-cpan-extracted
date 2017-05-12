#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::MockObject::Extends;
use URI;
use Catalyst::Plugin::Session::State::URI;

{

    package HashObj;
    use base qw/Class::Accessor/;

    __PACKAGE__->mk_accessors(qw/body path base content_type location status/);
}

my $req = Test::MockObject::Extends->new( HashObj->new );
$req->base( URI->new( "http://server/app/" ));

my $res = Test::MockObject::Extends->new( HashObj->new );

my $uri         = "http://www.woobling.org/";

{
    package MockCtx;
    use base qw/
        Catalyst::Plugin::Session
        Catalyst::Plugin::Session::State::URI
    /;
}

my $cxt = Test::MockObject::Extends->new("MockCtx");

$cxt->set_always( config => {} );
$cxt->set_always( request  => $req );
$cxt->set_always( response => $res );
$cxt->set_false("debug");

$cxt->setup_session;

$req->path("-/the session id");    # sri's bug
$cxt->prepare_path;

$res->body( my $body_ext_url = qq{foo <a href="$uri"></a> blah} );

my $called = 0;
$cxt->mock('rewrite_html_with_session_id', sub { $called++ });

$cxt->rewrite_body_with_session_id('foo');
ok $called;


#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst }
      or plan skip_all =>
      "Test::WWW::Mechanize::Catalyst is needed for this test";
    plan tests => 9;
}
use HTTP::Request;
{
    package AuthTestApp;
    use Catalyst qw/
      Authentication
      /;
    use Test::More;
    our %users;
    __PACKAGE__->config(authentication => {
        default_realm => 'test_proxy',
        realms => {
            test => {
                store => { 
                    class => 'Minimal',
                    users => \%users,
                },
                credential => { 
                    class => 'HTTP', 
                    type  => 'basic',
                    password_type => 'clear', 
                    password_field => 'password'
                },
            },
            test_proxy => {
                store => {
                    class => 'Minimal',
                    users => {
                        foo => { password => 'proxypass' }
                    },
                },
                credential => {
                    class => 'HTTP::Proxy',
                    url => 'http://localhost/moose',
                    type => 'basic',
                },
            }
        },
    });
    sub moose : Local {
        my ( $self, $c ) = @_;
        $c->authenticate({}, 'test');
	    $c->res->body( 'test realm:' . $c->user->id );
    }
    sub yak : Local {
        my ( $self, $c ) = @_;
        $c->authenticate({}, 'test_proxy');
	    $c->res->body( 'test_proxy realm:' . $c->user->id );
    }
    %users = (
        foo => { password         => "s3cr3t", },
    );
    __PACKAGE__->setup;
}
use Test::WWW::Mechanize::Catalyst qw/AuthTestApp/;
{
    no warnings qw/once redefine/;
    *Catalyst::Authentication::Credential::HTTP::Proxy::User::new = sub { Test::WWW::Mechanize::Catalyst->new };
}
SKIP: {
    
    skip 'Catalyst engine is not reenterant, this will not work', 5;
    last;
    
    my $mech = Test::WWW::Mechanize::Catalyst->new;
    {   # HTTP, no auth
#        $mech->get("http://localhost/moose");
        is( $mech->status, 401, "status is 401" ) or die $mech->content;
        $mech->content_lacks( "foo", "no output" );
    }
    
    {# HTTP with auth
        my $r = HTTP::Request->new( GET => "http://localhost/moose" );
        $r->authorization_basic(qw/foo s3cr3t/);
#        $mech->request($r);
        is( $mech->status, 200, "status is 200" );
        $mech->content_contains( "test realm:foo", "test realm:foo output" );
    }

    {   # HTTP with other auth
        my $r = HTTP::Request->new( GET => "http://localhost/moose" );
        $r->authorization_basic(qw/foo proxypass/);
#        $mech->request($r);
        is( $mech->status, 401, "status is 401" ) or die $mech->content;
    }
}

SKIP: {
    
    skip 'Catalyst engine is not reenterant, this will not work', 4;
    last;
    
    my $mech = Test::WWW::Mechanize::Catalyst->new;
    {   # Proxy, no auth
#        $mech->get("http://localhost/yak");
        is( $mech->status, 401, "status is 401" ) or die $mech->content;
        $mech->content_lacks( "foo", "no output" );
    }
    
    {   # Proxy with other auth
        my $r = HTTP::Request->new( GET => "http://localhost/yak" );
        $r->authorization_basic(qw/foo s3cr3t/);
#        $mech->request($r);
        is( $mech->status, 401, "status is 401" ) or die $mech->content;
    }

    {   # HTTP with other auth
        my $r = HTTP::Request->new( GET => "http://localhost/yak" );
        $r->authorization_basic(qw/foo proxypass/);
#        $mech->request($r);
        is( $mech->status, 200, "status is 200" );
        $mech->content_contains( "test_proxy realm:foo", "test_proxy realm:foo output" );
    }
}

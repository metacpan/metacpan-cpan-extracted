use strict;
use warnings;

use Test::More;

use Catalyst::Request;
use Catalyst::Request::REST::ForBrowsers;
use Catalyst::TraitFor::Request::REST::ForBrowsers;
use Moose::Meta::Class;
use HTTP::Headers;
use Catalyst::Log;

my $anon_class = Moose::Meta::Class->create_anon_class(
    superclasses => ['Catalyst::Request'],
    roles        => ['Catalyst::TraitFor::Request::REST::ForBrowsers'],
    cache        => 1,
)->name;

# We run the tests twice to make sure Catalyst::Request::REST::ForBrowsers is
# 100% back-compatible.
for my $class ( $anon_class, 'Catalyst::Request::REST::ForBrowsers' ) {
    {
        for my $method (qw( GET POST PUT DELETE )) {
            my $req = $class->new(
                _log => Catalyst::Log->new,
            );
            $req->method($method);
            $req->{_context} = 'MockContext';
            $req->parameters( {} );

            is(
                $req->method(), $method,
                "$method - not tunneled"
            );
        }
    }

    {
        for my $method (qw( PUT DELETE )) {
            my $req = $class->new(
                _log => Catalyst::Log->new,
            );
            $req->method('POST');
            $req->{_context} = 'MockContext';
            $req->parameters( { 'x-tunneled-method' => $method } );

            is(
                $req->method(), $method,
                "$method - tunneled with x-tunneled-method param"
            );
        }
    }

    {
        for my $method (qw( PUT DELETE )) {
            my $req = $class->new(
                _log => Catalyst::Log->new,
            );
            $req->method('POST');
            $req->{_context} = 'MockContext';
            $req->header( 'x-http-method-override' => $method );

            is(
                $req->method(), $method,
                "$method - tunneled with x-http-method-override header"
            );
        }
    }

    {
        for my $method (qw( PUT DELETE )) {
            my $req = $class->new(
                _log => Catalyst::Log->new,
            );
            $req->method('GET');
            $req->{_context} = 'MockContext';
            $req->parameters( { 'x-tunneled-method' => $method } );

            is(
                $req->method(), 'GET',
                'x-tunneled-method is ignore with a GET'
            );
        }
    }

    {
        my $req = $class->new(
            _log => Catalyst::Log->new,
        );
        $req->{_context} = 'MockContext';
        $req->method('GET');
        $req->parameters( {} );
        $req->headers( HTTP::Headers->new() );

        ok(
            $req->looks_like_browser(),
            'default is a browser'
        );
    }

    {
        for my $with (qw( HTTP.Request XMLHttpRequest )) {
            my $req = $class->new(
                _log => Catalyst::Log->new,
            );
            $req->{_context} = 'MockContext';
            $req->headers(
                HTTP::Headers->new( 'X-Requested-With' => $with ) );

            ok(
                !$req->looks_like_browser(),
                "not a browser - X-Request-With = $with"
            );
        }
    }

    {
        my $req = $class->new(
            _log => Catalyst::Log->new,
        );
        $req->{_context} = 'MockContext';
        $req->method('GET');
        $req->parameters( { 'content-type' => 'text/json' } );
        $req->headers( HTTP::Headers->new() );

        ok(
            !$req->looks_like_browser(),
            'forced non-HTML content-type is not a browser'
        );
    }

    {
        my $req = $class->new(
            _log => Catalyst::Log->new,
        );
        $req->{_context} = 'MockContext';
        $req->method('GET');
        $req->parameters( { 'content-type' => 'text/html' } );
        $req->headers( HTTP::Headers->new() );

        ok(
            $req->looks_like_browser(),
            'forced HTML content-type is not a browser'
        );
    }

    {
        my $req = $class->new(
            _log => Catalyst::Log->new,
        );
        $req->{_context} = 'MockContext';
        $req->method('GET');
        $req->parameters( {} );
        $req->headers(
            HTTP::Headers->new( 'Accept' => 'text/xml; q=0.4, */*; q=0.2' ) );

        ok(
            $req->looks_like_browser(),
            'if it accepts */* it is a browser'
        );
    }

    {
        my $req = $class->new(
            _log => Catalyst::Log->new,
        );
        $req->{_context} = 'MockContext';
        $req->method('GET');
        $req->parameters( {} );
        $req->headers(
            HTTP::Headers->new(
                'Accept' => 'text/html; q=0.4, text/xml; q=0.2'
            )
        );

        ok(
            $req->looks_like_browser(),
            'if it accepts text/html it is a browser'
        );
    }

    {
        my $req = $class->new(
            _log => Catalyst::Log->new,
        );
        $req->{_context} = 'MockContext';
        $req->method('GET');
        $req->parameters( {} );
        $req->headers(
            HTTP::Headers->new(
                'Accept' => 'application/xhtml+xml; q=0.4, text/xml; q=0.2'
            )
        );

        ok(
            $req->looks_like_browser(),
            'if it accepts application/xhtml+xml it is a browser'
        );
    }

    {
        my $req = $class->new(
            _log => Catalyst::Log->new,
        );
        $req->{_context} = 'MockContext';
        $req->method('GET');
        $req->parameters( {} );
        $req->headers(
            HTTP::Headers->new(
                'Accept' => 'text/json; q=0.4, text/xml; q=0.2'
            )
        );

        ok(
            !$req->looks_like_browser(),
            'provided an Accept header but does not accept html, is not a browser'
        );
    }
}

done_testing;

package MockContext;

sub prepare_body { }

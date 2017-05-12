package RPC::ExtDirect::Test::Util::AnyEvent;

use common::sense;

use Test::More;

use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::HTTPD::Util;

use URI::http;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Response;
use JSON;

use RPC::ExtDirect::Config;
use RPC::ExtDirect::Test::Util;

use base 'Exporter';

our @EXPORT = qw/
    run_tests
/;

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Run the test battery from the passed definitions
#

sub run_tests {
    my ($tests, $host, $port, @run_only) = @_;
    
    my $cmp_pkg   = 'RPC::ExtDirect::Test::Util';
    my $num_tests = @run_only || @$tests;
    
    plan tests => 5 * $num_tests;
    
    TEST:
    for my $test ( @$tests ) {
        my $name   = $test->{name};
        my $config = $test->{config};
        my $input  = $test->{input};
        my $output = $test->{output};
        
        next TEST if @run_only && !grep { lc $name eq lc $_ } @run_only;
        
        local $RPC::ExtDirect::Test::Pkg::PollProvider::WHAT_YOURE_HAVING
            = $config->{password};
        
        my $url           = $input->{anyevent_url} || $input->{url};
        my $method        = $input->{method};
        my $input_content = $input->{anyevent_content} || $input->{content}
                            || { type => 'raw_get', arg => [$url] };
        
        my $req = prepare_input 'AnyEvent', $input_content;

        # This is a bit hacky but AnyEvent::HTTPD is awfully picky
        # so we need to make sure the URI in the request contains
        # the host and the port
        {
            my $uri = $req->uri;
            bless $uri, 'URI::http';
            
            $uri->scheme('http');
            $uri->host($host);
            $uri->port($port);
        }
        
        if ( exists $config->{'-cgi_env'} ) {
            my $cookie = $config->{'-cgi_env'}->{HTTP_COOKIE};
            
            $req->header('Cookie', $cookie) if $cookie;
        }
        
        my $cfg_obj = RPC::ExtDirect::Config->new(
            debug_serialize => 1,
            %$config,
        );
        
        my $server = AnyEvent::HTTPD::ExtDirect->new(
            host   => $host,
            port   => $port,
            config => $cfg_obj,
        );
        
        $server->set_callbacks(
            api_path    => $cfg_obj->api_path,
            router_path => $cfg_obj->router_path,
            poll_path   => $cfg_obj->poll_path,
        );
        
        my $req_str = $req->as_string("\r\n");

        my $actual_host = $server->host;
        my $actual_port = $server->port;

        my $cv = AnyEvent::HTTPD::Util::test_connect(
            $actual_host, $actual_port, $req_str
        );
    
        my $http_resp_str = $cv->recv;
        my $res = HTTP::Response->parse($http_resp_str);
        
        if ( ok $res, "$name not empty" ) {
            my $want_status = $output->{status};
            my $have_status = $res->code;
            
            is $have_status, $want_status, "$name: HTTP status";
            
            my $want_type = $output->{content_type};
            my $have_type = $res->content_type;
            
            like $have_type, $want_type, "$name: content type";

            my $want_len = defined $output->{anyevent_content_length}
                         ? $output->{anyevent_content_length}
                         : $output->{content_length};
            my $have_len = $res->content_length;

            is $have_len, $want_len, "$name: content length";
            
            my $cmp_fn = $output->{comparator};
            my $want   = $output->{anyevent_content} || $output->{content};
            my $have   = $res->content;
            
            $cmp_pkg->$cmp_fn($have, $want, "$name: content");
        };
        
        $server->stop;
    };
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a raw GET call
#

sub raw_get {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url) = @_;
    
    my $req = HTTP::Request::Common::GET $url;
    $req->protocol('HTTP/1.0');
    
    return $req;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a raw POST call
#

sub raw_post {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url, $content) = @_;
    
    my $req = HTTP::Request::Common::POST $url,
                Content_Type => 'application/json',
                Content      => $content
           ;
    $req->protocol('HTTP/1.0');
    
    return $req;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a form call
#

sub form_post {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url, @fields) = @_;

    my $req = HTTP::Request::Common::POST $url, Content => [ @fields ];
    $req->protocol('HTTP/1.0');
    
    return $req;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new HTTP::Request object for a form call
# with file uploads
#

sub form_upload {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url, $files, @fields) = @_;

    my $type = 'application/octet-stream';

    my $req = HTTP::Request::Common::POST $url,
           Content_Type => 'form-data',
           Content      => [ @fields,
                             map {
                                    (   upload => [
                                            "t/data/cgi-data/$_",
                                            $_,
                                            'Content-Type' => $type,
                                        ]
                                    )
                                 } @$files
                           ]
    ;
    $req->protocol('HTTP/1.0');
    
    return $req;
}

1;

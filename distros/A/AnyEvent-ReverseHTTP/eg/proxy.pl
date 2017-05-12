#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Request::Common;
use AnyEvent::HTTP;
use AnyEvent::ReverseHTTP;

my $proxy_to = $ARGV[0] or die 'require proxy target';

my $w = AnyEvent::ReverseHTTP->new(
    on_register => sub {
        print "You can connect to your server at $_[0]\n";
    },
    on_request => sub {
        my $req = shift;
        my $resback = AnyEvent->condvar;

        my $target = $proxy_to . $req->uri;

        # proxy
        my %headers = map { $_ => $req->header($_) } $req->headers->header_field_names;
        http_request(
            $req->method, $target,
            headers => \%headers,
            body    => $req->content,
            sub {
                my ($body, $hdr) = @_;

                my $res = HTTP::Response->new( $hdr->{Status} );
                for my $header (keys %{ $hdr || {} }) {
                    $res->header( $header => $hdr->{$header} );
                }
                $res->content( $body );

                $resback->send($res);
            }
        );

        $resback;
    },
)->connect;

AnyEvent->condvar->recv;

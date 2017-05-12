#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use AnyEvent::Future qw( as_future_cb );
use AnyEvent::HTTP qw( http_get );

# Note this doesn't match the same spec as other Future-returning HTTP clients
# because its response value isn't the entire HTTP::Response, but instead a
# single string containing only the content.

sub HTTP_GET
{
   my ($url) = @_;
   return as_future_cb {
      my ( $done, $fail ) = @_;

      return http_get $url, sub {
         my ( $data, $headers ) = @_;
         defined $data ? $done->( $data ) : $fail->( $headers->{Reason} );
      };
   };
}

say HTTP_GET( $ARGV[0] )->get;

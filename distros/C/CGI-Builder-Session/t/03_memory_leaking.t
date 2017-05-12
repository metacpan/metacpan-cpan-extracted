; use strict
; use CGI

; $My::Test = 'A'

; package My::WebAppClass
; use CGI::Builder
  qw| CGI::Builder::Session
    |

; sub DESTROY
   { $My::Test .= 'B'
   }

; package main
; use Test::More tests => 1


; { my $wa = My::WebAppClass->new
  ; my $cs = $wa->cs
  ; $wa->capture('process')
  }

; $My::Test .= 'C'

; is( $My::Test
    , 'ABC'
    , 'Memory leaking test'
    )

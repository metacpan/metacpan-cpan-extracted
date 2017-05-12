; use strict
; use CGI

; $My::Test = 'A'

; package My::WebAppClass
; use CGI::Builder
  qw| CGI::Builder::Magic
    |

; sub DESTROY
   { $My::Test .= 'B'
   }

; package main
; use Test::More tests => 1


; { my $CBB = My::WebAppClass->new
  ; my $t = $CBB->tm
  ; $CBB->capture('process')
  }

; $My::Test .= 'C'

; is( $My::Test
    , 'ABC'
    , 'Memory leaking test'
    )

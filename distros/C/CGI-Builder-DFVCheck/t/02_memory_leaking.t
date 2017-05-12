; use strict
; use CGI

; $My::Test = 'A'

; package My::CBB
; use CGI::Builder
  qw| CGI::Builder::DFVCheck
    |

; sub DESTROY
   { $My::Test .= 'B'
   }

; package main
; use Test::More tests => 1


; { my $cbb = My::CBB->new
  ; my $dfv = $cbb->dfv_check( { required => 'email'
                              , msgs     => { prefix => 'err_' }
                              }
                            )
  ; $cbb->capture('process')
}

; $My::Test .= 'C'

; is( $My::Test
    , 'ABC'
    , 'Memory leaking test'
    )

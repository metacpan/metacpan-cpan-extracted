; use strict

; package one
; sub OH_init { print 'one' }
; sub OH_cleanup { print 'one' }

; package two

; use CGI::Builder
  qw| one
    |
; sub OH_init { print 'two' }
; sub OH_cleanup { print 'two' }

; package simpletwo
; sub OH_init { print 'simpletwo' }
; sub OH_cleanup { print 'simpletwo' }

; package three
; use CGI::Builder
  qw| one
      simpletwo
    |

; INIT
   { three->overrun_handler_map( 'init'    => [ qw(three simpletwo one) ]
                               , 'cleanup' => [ qw(three simpletwo one) ]
                               )
   ;
   }

; sub OH_init { print 'three' }
; sub OH_cleanup { print 'three' }


; package main

; use Test::More tests => 18


; is( $two::ISA[0]
    , 'one'
    )

; is( $two::ISA[1]
    , 'CGI::Builder'
    )

; is( two->overrun_handler_map('init')->[0]
    , 'one'
    )
; is( two->overrun_handler_map('cleanup')->[0]
    , 'two'
    )

; is( two->overrun_handler_map('init')->[1]
    , 'two'
    )
; is( two->overrun_handler_map('cleanup')->[1]
    , 'one'
    )
; use IO::Util qw|capture|

; is( ${+ capture{ two->CGI::Builder::_::exec('init') }}
    , 'onetwo'
    )

; is( ${+ capture{ two->CGI::Builder::_::exec('cleanup') }}
    , 'twoone'
    )

; use IO::Util qw|capture|
; my $o
; is( ${+ capture{ $o = two->new() } }
    , 'onetwo'
    )

### overtwo

; is( three->overrun_handler_map('init')->[0]
    , 'three'
    )
; is( three->overrun_handler_map('cleanup')->[0]
    , 'three'
    )

; is( three->overrun_handler_map('init')->[1]
    , 'simpletwo'
    )
; is( three->overrun_handler_map('cleanup')->[1]
    , 'simpletwo'
    )
; is( three->overrun_handler_map('init')->[2]
    , 'one'
    )
; is( three->overrun_handler_map('cleanup')->[2]
    , 'one'
    )
; use IO::Util qw|capture|

; is( ${+ capture{ three->CGI::Builder::_::exec('init') }}
    , 'threesimpletwoone'
    )

; is( ${+ capture{ three->CGI::Builder::_::exec('cleanup') }}
    , 'threesimpletwoone'
    )

; is( ${+ capture{ $o = three->new() } }
    , 'threesimpletwoone'
    )








































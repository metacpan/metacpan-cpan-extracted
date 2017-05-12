#!perl -w
; use strict
; use Test::More tests => 17

; BEGIN
  { chdir './t'
  ; require './Test.pm'
  }
###### QUERY #######

; my $ap1 = Test1->new( cgi => CGI->new({ p => 'mm' }) )
; my $o1 = $ap1->capture('process')
; ok($$o1 =~ /MM/)

; my $ap2 = Test2->new()
; my $o2 = $ap2->capture('process')
; ok($$o2 =~ /MM/)

; my $ap3 = Test3->new( cgi => CGI->new({ p => 'mm' }) )
; my $o3 = $ap3->capture('process')
; ok($$o3 =~ /ST/)

; my $ap4 = Test4->new( )
; my $o4 = $ap4->capture('process')
; ok($$o4 =~ /ST/)

; my $ap5 = Test5->new()
; my $o5 = $ap5->capture('process')
; ok($$o5 =~ /STST/)

; my $ap6 = Test6->new()
; my $o6 =$ap6->capture('process')
; ok($$o6 =~ /legal/)

# set param from new
; my $ap7 = Test5->new( my_data => 'my_data' )
; is( $ap7->my_data('my_data')
    , 'my_data'
    )

; my $ap8 = Test8->new( cgi => CGI->new({ p => 'one' }) )
; my $o8 = $ap8->capture('process')
; ok(  ($$o8 =~ /AoneAtwofixup/)
    && ($$o8 =~ /madness/)
    )

; my $ap9 = Test8->new( cgi => CGI->new({ p => 'redirect' }) )
; my $o9 = $ap9->capture('process')
; ok(  ($$o9 =~ /302 Moved/)
    && ($$o9 !~ /never printed/)
    && ($$o9 !~ /fixup/)
    && ($$o9 !~ /madness/)
    )

; my $ap10 = Test1->new( )
; my $o10 = $ap10->capture('process', 'not_found')
; ok($$o10 =~ /204 No Content/)

; my $ap11 = Test11->new( )
; $ap11->capture('process', 'myPage')
; ok( $ap11->test =~ /initpre_processSHpre_pagePHfixupcleanup/ )

; my $ap12 = Test11->new( )
; $ap12->capture('process', 'Auto')
; ok( $ap12->test =~ /initpre_processpre_pageAUTOLOADfixupcleanup/ )


; my $ap13 = Test12->new( conf_file => './conf.mml' )
; is $ap13->page_name, 'a_name'
; is $ap13->my_param, 'a_param'

; my $ap14 = Test12->new( conf_file => ['./conf.mml', 'conf2.mml'] )
; is $ap14->page_name, 'a_name2'
; is $ap14->my_param, 'a_param'
; is $ap14->my_param2, 'a_param2'

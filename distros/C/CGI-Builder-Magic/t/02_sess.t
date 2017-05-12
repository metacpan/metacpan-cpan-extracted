#!perl -w
; use strict
; BEGIN { chdir './t' }

; use Test::More
; eval "use CGI::Builder::Session"
; plan skip_all => "CGI::Builder::Session is not installed" if $@

; plan tests => 1
; require 'TestS.pm'

; my $ap1 = TestSess->new(page_name =>'sess')
; my $o1 = $ap1->capture('process')
; ok(  $$o1 =~ /start-->.{32}<--end/i )



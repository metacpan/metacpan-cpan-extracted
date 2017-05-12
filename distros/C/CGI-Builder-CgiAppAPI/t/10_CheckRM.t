#!perl -w
; use strict
; BEGIN { chdir './t' }


; use Test::More
; eval "use CGI::Builder::DFVCheck; use CGI::Builder::Magic;"
; plan skip_all => "CGI::Builder::DFVCheck or CGI::Builder::Magic is not installed" if $@

; plan tests => 1
; require './test/CheckRM_magic.pm'
; my $ap2 = MagicAppl1->new()
; my $o2 = $ap2->capture('process')
; ok(  $$o2 =~ /start--><span/ )

 

#!perl -w
; use strict


; use Test::More

; BEGIN { chdir './t' }

; eval "use CGI::Builder::DFVCheck"
; plan skip_all => "CGI::Builder::DFVCheck is not installed" if $@

; plan tests => 1
; require './test/CheckRM_basic.pm'
; my $ap1 = Appl1->new()
; my $o1 = $ap1->capture('process')
; ok(  $$o1 =~ /err_email <span/
    && $$o1 !~ /index content/
    )



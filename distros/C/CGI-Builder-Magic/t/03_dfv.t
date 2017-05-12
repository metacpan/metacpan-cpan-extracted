#!perl -w
; use strict

; BEGIN{ chdir './t' }

; use Test::More;
; eval "use CGI::Builder::DFVCheck"
; plan skip_all => "CGI::Builder::DFVCheck is not installed" if $@

; plan tests => 2
; require 'TestD.pm'


; my $ap1 = TestDFV->new()
; my $o1 = $ap1->capture('process')
; ok(  $$o1 =~ /start--><span.+<--end/i )

; my $ap2 = TestDFV->new(page_name => 'dfv')
; my $o2 = $ap2->capture('process')
; ok(  $$o2 =~ /start--><--end/i )



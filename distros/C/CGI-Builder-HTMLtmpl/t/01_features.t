#!perl -w
; use strict
; use Test::More tests => 6
#; use CGI



; BEGIN
   { chdir './t'
   ; require './Test.pm'
   }


# index.tmpl
; my $ap1 = HTAppl1->new()
; my $o1 = $ap1->capture('process')
; ok( $$o1 =~ /start->Hello<-end/ )

# bad param
; my $ap2 = HTAppl2->new()
; my $o2 = $ap2->capture('process')
; ok( $$o2 =~ /start->Hello<-end/ )

# filename override
; my $ap3 = HTAppl3->new()
; my $o3 = $ap3->capture('process')
; ok( $$o3 =~ /other start->Hello<-other end/ )


# filename + path override
; my $ap4 = HTAppl4->new()
; my $o4 = $ap4->capture('process')
; ok( $$o4 =~ /222 other start->Hello<-other end/ )

; my $ap5 = HTAppl5->new()
; my $o5 = $ap5->capture('process')
; ok( $$o5 =~ /222 other start->Hello<-other end/ )

; my $ap6 = HTAppl6->new()
; my $o6 = $ap6->capture('process')
; ok( $$o6 =~ /222 other start->Hello<-other end/ )


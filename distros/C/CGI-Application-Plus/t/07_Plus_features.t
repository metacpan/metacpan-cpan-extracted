#!perl -w
; use strict
; use Test::More tests => 6
; use CGI
; use CGI::Application::Plus::Util

# Capture and return output
; $ENV{CGI_APP_RETURN_ONLY} = 1;

; BEGIN
   { chdir './t'
   ; require 'test/AppPlus.pm'
   }

###### QUERY #######

; my $ap1 = ApplPlus1->new( query => CGI->new({ rm => 'mm' }) )
; my $o1 = $ap1->run()
; ok($o1 =~ /MM/)

; my $ap2 = ApplPlus2->new()
; my $o2 = $ap2->run()
 ; ok($o2 =~ /MM/)

#; my $ap3 = ApplPlus3->new( query => CGI->new({ rm => 'mm' }) )
#; my $o3 = eval { $ap3->run() }
#; ok($@)

####### SWITCH TO ##########

; my $ap4 = ApplPlus4->new( )
; my $o4 = $ap4->run()
; ok($o4 =~ /ST/)

; my $ap5 = ApplPlus5->new()
; my $o5 = $ap5->run()
; ok($o5 =~ /STST/)

; my $ap6 = ApplPlus6->new()
; my $o6 = eval { $ap6->run() }
; ok($@)

# set param from new
; my $ap7 = ApplPlus5->new( myParam => 'myPARAM' )
; is( $ap7->param('myParam')
    , 'myPARAM'
    )



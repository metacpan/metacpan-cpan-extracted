#!perl -w
; use strict
; use Test::More tests => 6
; use CGI

# Capture and return output
; $ENV{CGI_APP_RETURN_ONLY} = 1;

; BEGIN  { chdir './t' }
; use lib 'test'
; use AppPlus


###### QUERY #######

; my $ap1 = ApplPlus1->new( query => CGI->new({ rm => 'mm' }) )
; my $o1 = $ap1->run()
; ok($o1 =~ /MM/)

; my $ap2 = ApplPlus2->new()
; my $o2 = $ap2->run()
; ok($o2 =~ /MM/)

; my $ap3 = ApplPlus3->new( query => CGI->new({ rm => 'mm' }) )
; my $o3 = eval { $ap3->run() }
; ok($@)

####### SWITCH TO ##########

; my $ap4 = ApplPlus4->new( )
; my $o4 = $ap4->run()
; ok($o4 =~ /ST/)

; my $ap5 = ApplPlus5->new()
; my $o5 = $ap5->run()
; ok($o5 =~ /STST/)

# set param from new
; my $ap7 = ApplPlus5->new( my_Param => 'my_PARAM' )
; is( $ap7->param('my_Param')
    , 'my_PARAM'
    )



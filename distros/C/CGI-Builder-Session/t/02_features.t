#!perl -w
; use strict
; use Test::More tests => 3
; use CGI

; BEGIN
  { eval { require './t/Test.pm' }
        || require './Test.pm'
  }

  
###### QUERY #######

; my $SID ;

{
# session new
; my $ap1 = Test1->new( )
; $SID = $ap1->cs->id
; my $o1 = $ap1->capture('process')
; ok($$o1 =~ /Set-Cookie\: CGISESSID=$SID/)
}

{
# session new with other cookie
; my $ap3 = Test2->new()
; my $SID2 = $ap3->cs->id
; my $o3 = $ap3->capture('process')
; ok(  ($$o3 =~ /Set-Cookie\: CGISESSID=$SID2/)
    && ($$o3 =~ /Set-Cookie\: control=control/)
    )
}

{
# session not new
; my $ap2 = Test2->new(cgi => CGI->new( {CGISESSID => $SID} ) )
; my $o2 = $ap2->capture('process')
; ok(  ($$o2 !~ /Set-Cookie\: CGISESSID=/)
    && ($$o2 =~ /Set-Cookie\: control=control/)
    )
}

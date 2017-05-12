#!perl -w
; use strict
; use Test::More tests => 9
; use CGI
; use Data::Dumper

; BEGIN
  { chdir './t'
  ; require './Test.pm'
  }
   

# index.html + passing zone obj
; my $ap1 = ApplMagic1->new()
; my $o1 = $ap1->capture('process')
; ok( $$o1 =~ /text START ID1 ATTRIBUTES1 text ID2 text/ )

# lookup in param
; my $ap2 = ApplMagic2->new()
; $ap2->tm_new_args( lookups => scalar $ap2->param()
                    )
; my $o2 = $ap2->capture('process')
; ok( $$o2 =~ /text START ID1 text ID2 text/ )

# lookup without param
; $ap2->tm = undef
; delete $ap2->tm_new_args->{lookups}
; my $ap3 = ApplMagic2->new()
; my $o3 = $ap3->capture('process')
; ok( $$o3 =~ /text START  text ID2 text/ )


# lookup in *::Lookup from *::Lookup
; my $ap4 = ApplMagic4->new()
; my $o4 = $ap4->capture('process')
; ok( $$o4 =~ /text START ID1 text ID2 text/ )


# start.html + passing zone obj
; my $ap5 = ApplMagic5->new()
; my $o5 = $ap5->capture('process')
; ok( $$o5 =~ /text START ID1 ATTRIBUTES1 text ID2 text/ )


; my $ap6 = ApplMagic6->new(cgi => CGI->new({p=>'ENV_RM'}))
; my $o6 = $ap6->capture('process')
; ok( $$o6 =~ /WebApp 1.0/
    && $$o6 =~ /PATH/
    )

# 204 error
; my $ap7 = ApplMagic6->new(cgi => CGI->new({p=>'not_found'}))
; my $o7 = $ap7->capture('process')
; ok( $$o7 =~ /204 No Content/ )
    

; SKIP:
   { skip("HTML::FillInForm is not installed", 2)
     unless eval { require HTML::FillInForm }

   # FillInForm block
   ; my $ap8 = ApplMagic8->new( cgi => CGI->new( { name =>'domizio'
                                                 , surname=>'demichelis'
                                                 }
                                               )
                              , page_name => 'form'
                              
                              )
   ; my $o8 = $ap8->capture('process')
   ; ok(  $$o8 =~ /domizio.*demichelis/s )

   # automatic lookup of page_error inside the FillInForm block
   ; my $ap9 = ApplMagic8->new( cgi => CGI->new( { name =>'domizio'
                                                 , surname=>'demichelis'
                                                 }
                                               )
                              , page_name => 'form'
                              )
   ; $ap9->page_error(err_name => 'name_error')
   ; my $o9 = $ap9->capture('process')
   ; ok(  $$o9 =~ /domizio.*name_error.*demichelis/s )
   }





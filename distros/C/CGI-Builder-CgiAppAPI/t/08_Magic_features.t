#!perl -w
; use strict
; BEGIN{ chdir './t' }

; use CGI
# Prevent output to STDOUT
; $ENV{CGI_APP_RETURN_ONLY} = 1;

; use Test::More;

; eval "use CGI::Builder::Magic"
; plan skip_all => "CGI::Builder::Magic is not installed" if $@

; plan tests => 6;
; require './test/AppMagic.pm'

# start.html + passing zone obj
; my $ap1 = ApplMagic1->new()

; my $o1 = $ap1->run()
; ok( $o1 =~ /text START ID1 ATTRIBUTES1 text ID2 text/ )

# lookup in param
; my $ap2 = ApplMagic2->new()
; $ap2->tm_new_args( lookups => scalar $ap2->param() )
; my $o2 = $ap2->run()
; ok( $o2 =~ /text START ID1 text ID2 text/ )


; $ap2->tm = undef
; delete $ap2->tm_new_args->{lookups}
# lookup without param
; my $ap3 = ApplMagic2->new()
; my $o3 = $ap3->run()
; ok( $o3 =~ /text START  text ID2 text/ )

 
# lookup in *::Lookup from *::Lookup
; my $ap4 = ApplMagic4->new()
; my $o4 = $ap4->run()
; ok( $o4 =~ /text START ID1 text ID2 text/ )


# start.html + passing zone obj
; my $ap5 = ApplMagic5->new()
; my $o5 = $ap5->run()
; ok( $o5 =~ /text START ID1 ATTRIBUTES1 text ID2 text/ )

# start.html + passing zone obj
; my $ap6 = ApplMagic6->new(query => CGI->new({rm=>'ENV_RM'}))
; my $o6 = $ap6->run()
; ok( $o6 =~ /WebApp 1.0/
    && $o6 =~ /PATH/ )


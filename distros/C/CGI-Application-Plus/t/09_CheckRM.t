#!perl -w
; use strict


; use Test::More
; use CGI::Application::Plus::Util
; $ENV{CGI_APP_RETURN_ONLY} = 1;
 
; use lib 'test'
; BEGIN { chdir './t' }

; eval "use Data::FormValidator"
; plan skip_all => "Data::FormValidator is not installed" if $@

; plan tests => 3
; require 'AppCheckRM.pm'

# check method and props
; my $ap1 = ApplMagic1->new()
; my $o1 = $ap1->run()
; ok( $ap1->can('checkRM') )
; ok( $ap1->can('dfv_defaults') )
; ok( $ap1->can('dfv_results') )



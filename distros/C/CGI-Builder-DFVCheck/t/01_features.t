#!perl -w
; use strict
; use Test::More tests => 3

; our $TM

; BEGIN
   { chdir './t'
   ; require './Test.pm'
   ; if ( eval { require CGI::Builder::Magic })
      { $TM = 1
      ; require './MagicTest.pm'
      }
   }

# index.tmpl
; my $ap1 = Appl1->new()

; my $o1 = $ap1->capture('process')
; ok(  $$o1 =~ /err_email <span/
    && $$o1 !~ /index content/
    )
; isa_ok $ap1->dfv_results, 'Data::FormValidator::Results'
    
    
; SKIP:
   { skip("CGI::Builder::Magic is not installed", 1)
     unless $TM
   ; my $ap2 = MagicAppl1->new()
   ; my $o2 = $ap2->capture('process')
   ; ok(  $$o2 =~ /start--><span/ )
   }





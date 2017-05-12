; mkdir 'ses'

; package Test1
; use strict
; use CGI


; use CGI::Builder
  qw| CGI::Builder::Session
    |

; sub OH_init
   { my $s = shift
   ; $s->cs_new_args( DSN_param => { Directory => 'ses' } )
   }

; sub OH_pre_page
   { my $s = shift
   ; $s->page_content = $s->cs->id
   }


; package Test2
; use strict
; use CGI


; use CGI::Builder
  qw| CGI::Builder::Session
    |

; sub OH_init
   { my $s = shift
   ; my $cc = $s->cgi->cookie(control=>'control')
   ; $s->header(-cookie => $cc )
   ; $s->cs_new_args( DSN_param => { Directory => 'ses' } )
   }

; sub OH_pre_page
   { my $s = shift
   ; $s->page_content = $s->cs->id
   }
 
; 1

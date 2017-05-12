; package ApplPlus1

; use CGI::Builder
  qw| CGI::Builder::CgiAppAPI
    |
; use CGI

; sub RM_mm { $_[0]->page = 'MM' }
 
; package ApplPlus2
; use CGI::Builder
  qw| CGI::Builder::CgiAppAPI
    |; use CGI

; sub setup
   { my $s = shift
   ; $s->query = CGI->new( { rm => 'mm' } )
   }
   
; sub RM_mm { $_[0]->page = 'MM' }

; package ApplPlus3
; use CGI::Builder
  qw| CGI::Builder::CgiAppAPI
    |
; sub RM_mm
   { $_[0]->query = '' # illegal set in run method
   ; $_[0]->page = 'MM'
   }

; package ApplPlus4
; use CGI::Builder
  qw| CGI::Builder::CgiAppAPI
    |
; sub cgiapp_prerun
   { $_[0]->switch_to('st')
   }
   
; sub RM_st
   { $_[0]->page = 'ST'
   }

; package ApplPlus5
; use CGI::Builder
  qw| CGI::Builder::CgiAppAPI
    |
; sub cgiapp_prerun
   { $_[0]->switch_to('st')
   }
   
; sub RM_st
   { return $_[0]->switch_to('stst')
   ; $_[0]->page = 'ST'
   }

; sub RM_stst
   { $_[0]->page = 'STST'
   }


; 1

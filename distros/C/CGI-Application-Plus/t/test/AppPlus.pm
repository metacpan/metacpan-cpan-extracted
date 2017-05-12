; package ApplPlus1
; use base 'CGI::Application::Plus'
; use CGI

; sub RM_mm { $_[0]->page = 'MM' }
 
; package ApplPlus2
; use base 'CGI::Application::Plus'
; use CGI

; sub setup
   { my $s = shift
   ; $s->query = CGI->new( { rm => 'mm' } )
   }
   
; sub RM_mm { $_[0]->page = 'MM' }

; package ApplPlus3
; use base 'CGI::Application::Plus'

; sub RM_mm
   { $_[0]->query = '' # illegal set in run method
   ; $_[0]->page = 'MM'
   }

; package ApplPlus4
; use base 'CGI::Application::Plus'

; sub cgiapp_prerun
   { $_[0]->switch_to('st')
   }
   
; sub RM_st
   { $_[0]->page = 'ST'
   }

; package ApplPlus5
; use base 'CGI::Application::Plus'

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

; package ApplPlus6
; use base 'CGI::Application::Plus'


; sub RM_start { $_[0]->page = 'S' }

; sub cgiapp_postrun
   { $_[0]->switch_to('start') # illegal from here
   }

; 1

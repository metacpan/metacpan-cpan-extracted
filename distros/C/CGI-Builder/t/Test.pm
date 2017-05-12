       
; package Test1
; use CGI::Builder
; use CGI

; sub PH_mm { $_[0]->page_content = 'MM' }
 
; package Test2
; use CGI::Builder
; use CGI

; sub OH_init
   { my $s = shift
   ; $s->cgi = CGI->new( { p => 'mm' } )
   }
   
; sub PH_mm { $_[0]->page_content = 'MM' }

; package Test3
; use CGI::Builder

; sub PH_st
   { $_[0]->page_content = 'ST'
   }

   ; sub SH_mm
   { $_[0]->switch_to('st')
   }

; sub PH_mm
   { $_[0]->page_content = 'MM'
   }

; package Test4
; use CGI::Builder

; sub OH_pre_process
   { $_[0]->switch_to('st')
   }
   
; sub PH_st
   { $_[0]->page_content = 'ST'
   }

; package Test5
; use CGI::Builder

; sub OH_pre_process
   { $_[0]->switch_to('st')
   }
   
; sub PH_st
   { return $_[0]->switch_to('stst')
   ; $_[0]->page_content = 'ST'
   }

; sub PH_stst
   { $_[0]->page_content = 'STST'
   }

; package Test6
; use CGI::Builder


; sub PH_index { $_[0]->page_content = 'S' }

; sub PH_legal { $_[0]->page_content = 'legal' }

; sub OH_fixup
   { $_[0]->switch_to('legal') # illegal from here
   }
   

; package Test8
; use CGI::Builder

; sub OH_pre_page
   { $_[0]->page_content .= 'A'
   }

; sub PH_one
   { $_[0]->page_content .= 'one'
   ; $_[0]->switch_to('two')
   }

; sub PH_two
   { $_[0]->page_content .= 'two'
   }
   
; sub SH_redirect
   { return $_[0]->redirect('http://blabla')
   }
   
; sub PH_redirect
   { $_[0]->page_content .= 'never printed'
   }

; sub OH_fixup
   { $_[0]->page_content .= 'fixup'
   ; $_[0]->header(-private=>'madness')
   }
   
; package Test11
; use CGI::Builder

; use Object::props 'test'

; sub OH_init
   { $_[0]->test = 'init'
   }

; sub OH_pre_process
   { $_[0]->test .= 'pre_process'
   }

; sub SH_myPage
   { $_[0]->test .= 'SH'
   }

; sub OH_pre_page
   { $_[0]->test .= 'pre_page'
   }

; sub PH_myPage
   { $_[0]->test .= 'PH'
   }

; sub PH_AUTOLOAD
   { $_[0]->test .= 'AUTOLOAD'
   }

; sub OH_fixup
   { $_[0]->test .= 'fixup'
   }

; sub OH_cleanup
   { $_[0]->test .= 'cleanup'
   }


; package Test12
; use CGI::Builder
  qw| CGI::Builder::Conf
    |
    

; 1



; package Appl1

; use CGI::Builder
  qw| CGI::Builder::DFVCheck
      CGI::Builder::CgiAppAPI
    |

; sub SH_start
   { my $s = shift
   ; $s->checkRM( { required => 'email'
                  , msgs     => { prefix => 'err_' }
                  }
                )
                || $s->switch_to('myOtherPage')
   }

; sub RM_start
   { my $s = shift
   ; $s->page_content = 'start content'
   }
    
; sub OH_pre_page
   { my $s  = shift;
   # do something with page_errors
   ; my $E = $s->page_error
   ; while ( my($field, $err) = each %{$E} )
      { $s->page_content .= "$field $err\n"
      }
   }


; 1






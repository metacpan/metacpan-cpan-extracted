

; package Appl1

; use CGI::Builder
  qw| CGI::Builder::DFVCheck
    |

; sub SH_index
   { my $s = shift
   ; my $res = $s->dfv_check( { required => 'email'
                    , msgs     => { prefix => 'err_' }
                    }
                  ) || $s->switch_to('myOtherPage')
   }

; sub PH_index
   { my $s = shift
   ; $s->page_content = 'index content'
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






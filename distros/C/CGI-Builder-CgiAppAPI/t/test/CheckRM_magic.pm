

; package MagicAppl1

; use CGI::Builder
  qw| CGI::Builder::DFVCheck
      CGI::Builder::Magic
      CGI::Builder::CgiAppAPI

    |

; sub SH_index
   { my $s = shift
   ; $s->checkRM( { required => 'email'
                  , msgs     => { prefix => 'err_' }
                  }
                )
                || $s->switch_to('myOtherPage')
   }


; 1






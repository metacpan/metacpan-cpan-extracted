; package TestDFV

; use CGI::Builder
  qw| CGI::Builder::DFVCheck
      CGI::Builder::Magic
    |
    

; sub SH_index
   { my $s = shift
   ; $s->dfv_check( { required => 'email'
                    , msgs     => { prefix => 'err_' }}
                  )
                  || $s->switch_to('dfv')
   }

; 1

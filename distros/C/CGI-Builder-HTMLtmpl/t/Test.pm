

; package HTAppl1

; use CGI::Builder
  qw| CGI::Builder::HTMLtmpl
    |
 
; sub PH_index
   { my $s = shift
   # deprecated but should work in this situation
   ; $s->ht->param(myVar=>'Hello')
   }


; package HTAppl2

; use CGI::Builder
  qw| CGI::Builder::HTMLtmpl
    |
 
 
; sub OH_init
   { my $s = shift
   # deprecated but should work in this situation
   ; $s->ht_new_args( die_on_bad_params => 0 )
   }
   
; sub PH_index
   { my $s = shift
   # deprecated but should work in this situation
   ; $s->ht->param( myVar  => 'Hello'
                  , badPar => 'peace' )
   }


; package HTAppl3

; use CGI::Builder
  qw| CGI::Builder::HTMLtmpl
    |
 
   
; sub PH_index
   { my $s = shift
   ; $s->ht_new_args( filename => 'other.tmpl' )
   # deprecated but should work in this situation
   ; $s->ht->param( myVar  => 'Hello' )
   }

; package HTAppl4

; use CGI::Builder
  qw| CGI::Builder::HTMLtmpl
    |
 
; sub OH_init
   { my $s = shift
   ; $s->ht_new_args( path => ['./tm2'] )
   }
      
; sub PH_index
   { my $s = shift
   ; $s->ht_new_args( filename => 'other.tmpl')
   ; $s->ht_param( myVar  => 'Hello' )
   }

; package HTAppl5

; use CGI::Builder
  qw| CGI::Builder::HTMLtmpl
    |

; sub OH_init
   { my $s = shift
   ; $s->ht_new_args( path => ['./tm2'] )
   }
    
; sub OH_pre_process
   { my $s= shift
   ; $s->ht_param( myVar  => 'Hello' )
   }
   
; sub PH_index
   { my $s = shift
   ; $s->switch_to('other')
   }

; package HTAppl6

; use CGI::Builder
  qw| CGI::Builder::HTMLtmpl
    |
    
; sub OH_init
   { my $s = shift
   ; $s->ht_new_args( path => ['./tm2'] )
   }
   
; sub OH_pre_process
   { my $s= shift
   ; $s->ht_param( myVar  => 'Hello' )
   }
   
; sub PH_index
   { my $s = shift
   ; $s->switch_to('two')
   }
   
; sub PH_two
   { my $s = shift
   ; $s->switch_to('unknown')
   }

; sub PH_AUTOLOAD
   { my $s = shift
   ; $s->switch_to('other')
   }
   
; 1






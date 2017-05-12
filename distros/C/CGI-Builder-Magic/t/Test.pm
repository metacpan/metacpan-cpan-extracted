

; package ApplMagic1

; use CGI::Builder
  qw| CGI::Builder::Magic
    |
    
; package ApplMagic1::Lookups
; sub my_ID1 { 'ID1'. $_[1]->attributes }
; our $my_ID2 = 'ID2'



; package ApplMagic2
; use CGI::Builder
  qw| CGI::Builder::Magic
    |

; sub OH_init
   { $_[0]->my_ID1 = 'ID1'
   }

; package ApplMagic2::Lookups
; our $my_ID2 = 'ID2'



; package ApplMagic4
; use CGI::Builder
  qw| CGI::Builder::Magic
    |

; push our @ISA, 'ApplMagic4::Lookups'

; sub OH_init
   { my $s = shift
      ; push @{ref($s).'ISA'},  ref($s) . '::Lookups'
}

; package ApplMagic4::Lookups
; our $my_ID2 = 'ID2'

; sub my_ID1 { $_[0]->_my_ID1 }

; sub _my_ID1 { 'ID1' }




; package ApplMagic5
; use CGI::Builder
  qw| CGI::Builder::Magic
    |

; sub OH_init
   { $_[0]->tm_lookups_package = 'ApplMagic5::dd'
   }

; package ApplMagic5::dd
; sub my_ID1 { 'ID1'. $_[1]->attributes }
; our $my_ID2 = 'ID2'



; package ApplMagic6
; use CGI::Builder
  qw| CGI::Builder::Magic
    |


; package ApplMagic6::Lookups

; our $app_name = 'WebApp 1.0'


; sub Time { scalar localtime }

; sub ENV_table
   { my @table
   ; while (my @line = each %ENV)
      { push @table, \@line
      }
   ; \@table
   }
   
; package ApplMagic8
; use CGI::Builder
  qw| CGI::Builder::Magic
    |

#; __PACKAGE__->tm_extra_value_handlers( FillInForm => 1 )

; 1





; package ApplMagic1
; use base 'CGI::Application::Magic'
 
; package ApplMagic1::Lookups
; sub myID1 { 'ID1'. $_[1]->attributes }
; our $myID2 = 'ID2'



; package ApplMagic2
; use base 'CGI::Application::Magic'

; sub setup
   { $_[0]->myID1 = 'ID1'
   }
   
; package ApplMagic2::Lookups
; our $myID2 = 'ID2'



; package ApplMagic4
; use base 'CGI::Application::Magic'
; push our @ISA, 'ApplMagic4::Lookups'

; sub setup
   { my $s = shift
      ; push @{ref($s).'ISA'},  ref($s) . '::Lookups'
}
   
; package ApplMagic4::Lookups
; our $myID2 = 'ID2'

; sub myID1 { $_[0]->_myID1 }

; sub _myID1 { 'ID1' }




; package ApplMagic5
; use base 'CGI::Application::Magic'
; sub setup
   { $_[0]->tm_lookups_package = 'ApplMagic5::dd'
   }
 
; package ApplMagic5::dd
; sub myID1 { 'ID1'. $_[1]->attributes }
; our $myID2 = 'ID2'



; package ApplMagic6
; use base 'CGI::Application::Magic'

 
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

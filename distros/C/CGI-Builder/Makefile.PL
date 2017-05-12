# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use 5.006_001
; use ExtUtils::MakeMaker

; my $pm = 'lib/CGI/Builder.pm'

; WriteMakefile
   ( NAME           => 'CGI::Builder'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR        => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM => $pm
       )
     : ()
   , PREREQ_PM      => { 'Class::constr'  => 2.1
                       , 'Class::props'   => 2.1
                       , 'Class::groups'  => 2.1
                       , 'Object::props'  => 2.1
                       , 'Object::groups' => 2.1
                       , 'Class::Util'    => 2.1
                       , 'IO::Util'       => 1.46
                       }
   )

; 1

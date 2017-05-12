# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use ExtUtils::MakeMaker

; my $pm = 'lib/CGI/Builder/Session.pm'

; WriteMakefile
   ( NAME           => 'CGI::Builder::Session'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR     => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM => $pm
       )
     : ()
   , PREREQ_PM      => { 'CGI::Builder'   => 1.2
                       , 'Object::props'  => 1.62
                       , 'Object::groups' => 1.62
                       , 'CGI::Session'   => 3.95
                       , 'File::Spec'     => 0
                       }
   )


; 1

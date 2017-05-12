# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use ExtUtils::MakeMaker

; my $pm = 'lib/CGI/Builder/CgiAppAPI.pm'

; WriteMakefile
   ( NAME           => 'CGI::Builder::CgiAppAPI'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR        => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM => $pm
       )
     : ()
   , PREREQ_PM      => { 'CGI::Builder'   => 1.3
                       , 'Object::props'  => 2
                       , 'Object::groups' => 2
                       }
   )


; 1

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use ExtUtils::MakeMaker

; my $pm = 'lib/CGI/Builder/Magic.pm'

; WriteMakefile
   ( NAME           => 'CGI::Builder::Magic'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR         => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM  => $pm
       )
     : ()
   , PREREQ_PM      => { 'CGI::Builder'    => 1.3
                       , 'Class::props'    => 2.1
                       , 'Class::groups'   => 2.1
                       , 'Object::props'   => 2.1
                       , 'Class::Util'     => 2.1
                       , 'Template::Magic' => 1.36
                       }
   )


; 1

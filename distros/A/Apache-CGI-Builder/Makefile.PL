# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use ExtUtils::MakeMaker

; my $pm = 'lib/Apache/CGI/Builder.pm'

; WriteMakefile
   ( NAME           => 'Apache::CGI::Builder'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR         => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM  => $pm
       )
     : ()
   , PREREQ_PM      => { 'CGI::Builder'  => 1.2
                       , 'Class::props'  => 1.62
                       , 'Object::props' => 1.62
                       , 'mod_perl'      => 0
                       }
   )
                          

; 1

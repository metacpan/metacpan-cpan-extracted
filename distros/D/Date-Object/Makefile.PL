###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Date::Object' ,
    'VERSION_FROM'  => 'lib/Date/Object.pm' ,
    #'PREREQ_PM'     => {'Foo'  => 0.01} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Date/Object.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;


###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Config::XMLPerl' ,
    'VERSION_FROM'  => 'lib/Config/XMLPerl.pm' ,
    'PREREQ_PM'     => {'XML::Smart'  => 1.5} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Config/XMLPerl.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;


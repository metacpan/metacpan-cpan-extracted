###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Class::HPLOO',
    'VERSION_FROM' => 'lib/Class/HPLOO.pm',
    'PREREQ_PM'    => {
                       'Filter::Simple'  => 0.02 ,
                       'Filter::Util::Call' => 1.06 ,
                       'Text::Balanced' => 1.89 ,
                      } ,
    'EXE_FILES'     => [ qw(script/build-hploo) ],
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Class/HPLOO.pm',
        AUTHOR        => 'Graciliano M. P. <gmpassos@cpan.org>'
       ) : ()
     ),
);

1;



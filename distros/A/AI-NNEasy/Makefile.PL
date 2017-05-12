###############
# MAKEFILE.PL #
###############

use Class::HPLOO::MakeMaker ;

WriteMakefile(
    'NAME'          => 'AI::NNEasy' ,
    'VERSION_FROM'  => 'lib/AI/NNEasy.pm' ,
    'PREREQ_PM'     => {
      'Class::HPLOO'  => 0.21 ,
      'Inline'        => 0.44 ,
    } ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/AI/NNEasy.pm',
        AUTHOR        => 'Graciliano M. P. <gmpassos@cpan.org>'
       ) : ()
     ),
);

#######
# END #
#######

1;


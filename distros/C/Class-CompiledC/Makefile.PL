use 5.008007;
use ExtUtils::MakeMaker;

WriteMakefile
(
        NAME           => 'Class::CompiledC',
        VERSION_FROM   => 'lib/Class/CompiledC.pm', 
        PREREQ_PM      => {
                                Inline => 0.44,
                          }, 
        ABSTRACT_FROM  => 'lib/Class/CompiledC.pm', 
        AUTHOR         => 'blackhat.blade <blade@focusline.de>',
);

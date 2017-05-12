use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Data::LetterTree',
    VERSION_FROM      => 'lib/Data/LetterTree.pm',
    ABSTRACT_FROM     => 'lib/Data/LetterTree.pm',
    AUTHOR            => 'Guillaume Rousse <Guillaume.Rousse@inria.fr>',
    LIBS              => ['-llettertree'],
);

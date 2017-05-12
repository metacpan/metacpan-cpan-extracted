use Inline::MakeMaker;

WriteMakefile(
    NAME => 'DMI::Decode',
    VERSION_FROM => 'Decode.pm',
    PREREQ_PM => { Inline => 0.44, },
);

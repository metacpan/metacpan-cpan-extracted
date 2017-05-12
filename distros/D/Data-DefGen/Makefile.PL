use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => "Data::DefGen",
    VERSION_FROM     => "lib/Data/DefGen.pm",
    ABSTRACT_FROM    => "lib/Data/DefGen.pm",
    LICENSE          => "perl",
    AUTHOR           => "Gerald Lai <glai at cpan dot org>",

    ## DEPENDENCIES ##
    PREREQ_PM => {
        "Scalar::Util" => 0,
    },
);

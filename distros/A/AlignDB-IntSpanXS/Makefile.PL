use 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'AlignDB::IntSpanXS',
    VERSION_FROM  => 'lib/AlignDB/IntSpanXS.pm',
    PREREQ_PM     => { "Scalar::Util::Numeric" => 0, },
    TEST_REQUIRES => { "Test::More" => "0.88" },
    ABSTRACT_FROM => 'lib/AlignDB/IntSpanXS.pm',
    AUTHOR        => "Qiang Wang <wang-q\@outlook.com>",
    LIBS          => '',
    DEFINE        => '',                                   # '-DHAVE_SOMETHING'
    INC           => '-I. ',
    OBJECT        => 'intspan.o xs.o',
);

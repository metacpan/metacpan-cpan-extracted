use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BDB::Wrapper',
    VERSION_FROM      => 'lib/BDB/Wrapper.pm', # finds $VERSION
    PREREQ_PM         => {BerkeleyDB=>0, File::Spec=>0}, # e.g., Module::Name => 1.1
    ABSTRACT          => 'The module to use BerkeleyDB.pm with good option easily',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Hajime Kurita / Admin of http://sakuhindb.com/ & http://minakoe.jp/') : ()),
);
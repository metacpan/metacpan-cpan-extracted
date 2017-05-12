use 5.012001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'DBM::Deep::Blue',
    ABSTRACT          => 'Memory Mapped Paged Permanent Perl Objects', 
    AUTHOR            => 'Philip R Brenan at gmail dot com',
    VERSION_FROM      => 'lib/DBM/Deep/Blue.pm',                        
#   CCFLAGS           => '-ggdb -O0 ',                                  
    CCFLAGS           => '-O9       ',                                  
);

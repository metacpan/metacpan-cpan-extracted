use 5.008005;
use ExtUtils::MakeMaker;

my $CXX = $ENV{CXX} || 'c++';

WriteMakefile(
    NAME           => 'Algorithm::Statistic',
    VERSION_FROM   => 'lib/Algorithm/Statistic.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Test::Requires' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM  => 'lib/Algorithm/Statistic.pm',
    AUTHOR         => 'Igor Karbachinsky',
    LIBS           => [''],
    DEFINE         => '',
    CC             => $CXX,
    LD             => $CXX,
    INC            => '-I include/ -std=c++11 -O2',
    XSOPT          => '-C++',
    OBJECT         => '$(O_FILES)',
);


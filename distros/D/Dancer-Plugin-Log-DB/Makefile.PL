use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Log::DB',
    AUTHOR              => q{Nikolay Aviltsev <navi@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/Plugin/Log/DB.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/Log/DB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'DBD::SQLite' => 0,
        'Test::More' => 0,
    	'Time::Piece' => 0,
    	'Dancer' => '1.0',
    	'Dancer::Plugin::Database' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-Log-DB-*' },
);

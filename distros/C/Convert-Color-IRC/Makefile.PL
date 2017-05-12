use strict;
use warnings;
use ExtUtils::MakeMaker;

my @test_files = qw(t/*.t);


WriteMakefile(
    NAME                => 'Convert::Color::IRC',
    AUTHOR              => 'Jason Felds <wolfman.ncsu2000@gmail.com>',
    VERSION_FROM        => 'lib/Convert/Color/IRC.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM           => {
      'Convert::Color::RGB8' => 0.01,
      'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Convert-Color-IRC-*' },
    test                => { TESTS => "@test_files" },
);

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	
    META_MERGE => {
       x_contributors => [
        'Christophe Ivorra <civ@maelink.com>',
       ],
    'meta-spec' => { version => '1.0.5' },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/maelink/Chorus-Engine.git',
             web  => 'https://github.com/maelink/Chorus-Engine',
         },
     },
    },


    NAME                => 'Chorus::Expert',
    AUTHOR              => q{Christophe Ivorra <ch.ivorra@free.fr>},
    VERSION_FROM        => 'lib/Chorus/Expert.pm',
    ABSTRACT_FROM       => 'lib/Chorus/Expert.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Chorus-Expert-*' },
);

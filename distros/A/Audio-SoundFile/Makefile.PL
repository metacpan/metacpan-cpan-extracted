# -*- mode: text -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Audio::SoundFile',
              VERSION_FROM => 'SoundFile.pm',
              DIR          => [qw(Header Reader Writer)],
              PREREQ_PM    => {
                PDL::Core      => 0,
                PDL::Core::Dev => 0,
              });

# -*- mode: text -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Audio::SoundFile::Header',
              VERSION_FROM => 'Header.pm',
              OBJECT       => 'Header.o header.o',
              INC          => '-I.',
              LIBS         => [qw(-lsndfile)]);

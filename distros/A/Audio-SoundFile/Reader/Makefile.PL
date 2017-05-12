# -*- mode: text -*-

use ExtUtils::MakeMaker;

use PDL::Core::Dev;

push(@{$CF->{INC}}, '-I../Header');
push(@{$CF->{INC}}, PDL_INST_INCLUDE);

push(@{$CF->{TYPEMAPS}}, 'typemap');
push(@{$CF->{TYPEMAPS}}, PDL_INST_TYPEMAP);

WriteMakefile(NAME         => 'Audio::SoundFile::Reader',
              VERSION_FROM => 'Reader.pm',
              OBJECT       => 'Reader.o ../Header/header.o',
              INC          => join(" ", @{$CF->{INC}}),
              TYPEMAPS     => [@{$CF->{TYPEMAPS}}],
              LIBS         => [qw(-lsndfile)]);

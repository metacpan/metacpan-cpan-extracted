use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::OpenMP;

subtest 'syntax and interface' => sub {
  alien_ok 'Alien::OpenMP', 'public interface check for Alien::Base'; 
  is +Alien::OpenMP->install_type, 'system', 'no share install is possible';
};

subtest 'has options' => sub {
  like +Alien::OpenMP->cflags,    qr{-fopenmp},           q{Found expected OpenMP compiler switch for gcc/clang.};
  like +Alien::OpenMP->lddlflags, qr{(?:-lomp|-fopenmp)}, q{Found expected OpenMP linker switch for gcc/clang.};
};

done_testing;

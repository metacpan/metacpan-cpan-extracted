BEGIN { $ENV{CC} = 'xyz-cc' }
use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::OpenMP::configure;
use Path::Tiny;
use Capture::Tiny qw(capture);

subtest 'CC environment variable' => sub {
  local $Alien::OpenMP::configure::OS = 'linux';
  Alien::OpenMP::configure->_reset;
  is $Alien::OpenMP::configure::CCNAME, 'xyz-cc', 'esoteric compiler name';
  ok !Alien::OpenMP::configure->is_known, q{not known};
};

subtest 'gcc' => sub {
  local $Alien::OpenMP::configure::CCNAME = 'gcc';
  local $Alien::OpenMP::configure::OS     = 'linux';
  my $omp_flag = q{-fopenmp};
  Alien::OpenMP::configure->_reset;
  is +Alien::OpenMP::configure->is_known,  1, q{known};
  is +Alien::OpenMP::configure->cflags,    $omp_flag, q{Found expected OpenMP compiler switch for gcc.};
  is +Alien::OpenMP::configure->lddlflags, $omp_flag, q{Found expected OpenMP linker switch for gcc.};
};

subtest 'darwin clang/gcc homebrew' => sub {
  local $Alien::OpenMP::configure::CCNAME = 'gcc';
  local $Alien::OpenMP::configure::OS     = 'darwin';
  local $ENV{PATH}                        = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
  Alien::OpenMP::configure->_reset;
  is +Alien::OpenMP::configure->is_known, 1,                    q{known};
  like +Alien::OpenMP::configure->cflags, qr{-Xclang -fopenmp}, q{Found expected OpenMP compiler switch for gcc/clang.};
  like +Alien::OpenMP::configure->lddlflags, qr{-lomp},         q{Found expected OpenMP linker switch for gcc/clang.};
  like +Alien::OpenMP::configure->cflags,    qr{-I/usr/local/include}, q{Found path to include headers};
};

subtest 'darwin clang/gcc macports' => sub {
  plan skip_all => 'Mocking does not work on MSWin32'
    if $^O eq 'MSWin32';
  local $Alien::OpenMP::configure::CCNAME = 'gcc';
  local $Alien::OpenMP::configure::OS     = 'darwin';
  local $ENV{PATH}                        = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";

  # create a mock port executable
  my $tempdir = Path::Tiny->tempdir();
  my $port    = $tempdir->child('bin', 'port');
  $port->parent->mkpath;
  $port->spew("#!/bin/bash");
  $port->chmod(0755);
  $ENV{PATH} .= ":$tempdir/bin";
  Alien::OpenMP::configure->_reset;
  is +Alien::OpenMP::configure->is_known, 1,                    q{known};
  like +Alien::OpenMP::configure->cflags, qr{-Xclang -fopenmp}, q{Found expected OpenMP compiler switch for gcc/clang.};
  like +Alien::OpenMP::configure->lddlflags, qr{-lomp},         q{Found expected OpenMP linker switch for gcc/clang.};
  like +Alien::OpenMP::configure->cflags,    qr{-I$tempdir/include/libomp}, q{Found path to include headers};
  like +Alien::OpenMP::configure->libs,      qr{-L$tempdir/lib/libomp},     q{Found path to library};
};

subtest 'unknown and therefore unsupported' => sub {
  local $Alien::OpenMP::configure::CCNAME = q{unsupported xyz};
  local $Alien::OpenMP::configure::OS     = q{foobar-os};
  Alien::OpenMP::configure->_reset;

  ok !Alien::OpenMP::configure->is_known, 'not known AKA unsupported';
  is +Alien::OpenMP::configure->cflags, q{}, 'empty string';
  is +Alien::OpenMP::configure->libs,   q{}, 'empty string';

  my ($stdout, $stderr, @result) = capture { Alien::OpenMP::configure->unsupported; 1 };
  is_deeply \@result, [1], 'no errors';
  like $stdout, qr{^OS Unsupported},                                         'Message for ExtUtils::MakeMaker';
  like $stderr, qr{This version of unsupported xyz does not support OpenMP}, 'unsupported compiler name';
};

subtest 'darwin, missing dependencies' => sub {
  local $Alien::OpenMP::configure::CCNAME = q{clang};
  local $Alien::OpenMP::configure::OS     = q{darwin};
  local $ENV{PATH}                        = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
  Alien::OpenMP::configure->_reset;
  ok +Alien::OpenMP::configure->is_known, 'known';

  my ($stdout, $stderr, @result) = capture { Alien::OpenMP::configure->unsupported; 1 };
  is_deeply \@result, [1], 'no errors';
  like $stdout, qr{^OS Unsupported},                                      'Message for ExtUtils::MakeMaker';
  like $stderr, qr{This version of clang does not support OpenMP},        'clang missing openmp support';
  like $stderr, qr{Support can be enabled by using Homebrew or Macports}, 'unsupported compiler name';
};


done_testing;

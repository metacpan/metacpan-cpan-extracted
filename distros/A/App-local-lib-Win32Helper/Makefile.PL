use strict;
use warnings;
use ExtUtils::MakeMaker;

warn "MS Windows only" and exit 1 unless $^O eq 'MSWin32';

WriteMakefile(
    NAME         => 'App::local::lib::Win32Helper',
    AUTHOR       => 'Curtis Jewell',
    VERSION_FROM => 'lib/App/local/lib/Win32Helper.pm',
    ABSTRACT     => 'Helper for Win32 users of local::lib',
    LICENSE      => 'perl_5',
    EXE_FILES    => [ 'script/llw32helper.pl' ],
    PREREQ_PM    => {
        'local::lib'            => '1.004007',
        'IO::Interactive'       => '0.0.5',
        'File::HomeDir'         => '0.81',
        'File::Spec::Functions' => '3.2701',
        'Win32::TieRegistry'    => '0.26',
        'Test::More'            => '0.42',
        'Test::Script'          => '1.07',
    },
    MIN_PERL_VERSION => '5.008',
    META_MERGE       => {
      resources => {
        repository => 'https://github.com/StrawberryPerl/App-local-lib-Win32Helper',
      },
    },
    dist => {
      PREOP    => 'pod2text lib/App/local/lib/Win32Helper.pm > README',
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : (TARFLAGS => '--owner=0 --group=0 -cvf')),
    },
);

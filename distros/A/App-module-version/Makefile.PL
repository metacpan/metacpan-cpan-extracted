use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::module::version',
    AUTHOR           => 'Curtis Jewell, <csjewell@cpan.org>',
    VERSION_FROM     => 'lib/App/module/version.pm',
    ABSTRACT_FROM    => 'lib/App/module/version.pm',
    LICENSE          => 'perl',
    EXE_FILES        => [ 'script/module-version' ],
    MIN_PERL_VERSION => 5.008009,
    PREREQ_PM        => {
      'Test::More'   => 0,
      'Getopt::Long' => 2.13,
      'Pod::Usage'   => 0,
      'English'      => 0,
    },
);

# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

## no critic (Policy)

use 5.026;
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'App::ArduinoBuilder',
    DISTNAME         => 'App-ArduinoBuilder',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/App/ArduinoBuilder.pm',
    ABSTRACT         => q{All-in-one build system for Arduino programs},
    LICENSE          => 'mit',
    EXE_FILES        => ['script/arduino_builder',],
    MIN_PERL_VERSION => '5.026',
    MAN3PODS         => {},
    # Directories in which we look for Makefile.PL. In general could be omitted but is needed in case there
    # is a file named Makefile.PL in a sub-directory. Should be customized if such a file needs to be
    # processed by ExtUtils.
    DIR              => [],
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      no_index => {
        directory => [ 'local', 'vendor', 't' ],
        namespace => ['App::ArduinoBuilder',],
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/arduino_builder.git',
          web => 'https://github.com/mkende/arduino_builder',
        },
        bugtracker => {
          web => 'https://github.com/mkende/arduino_builder/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean => { FILES => 'App-ArduinoBuilder-*' },
);

sub MY::postamble {
  my ($self) = @_;

  my @postamble;
  push @postamble, ::postamble() if *::postamble{CODE};

  # Solaris has a weird (?) make that does not support our `export` statements.
  push @postamble, <<"MAKE_FRAGMENT" unless $^O eq 'solaris';
distupload: distcheck disttest
\t\$(MAKE) tardist
\tcpan-upload --directory Dist-Setup \$(DISTVNAME).tar\$(SUFFIX)

cover:
\tcover -test

critic: export EXTENDED_TESTING = 1
critic: all
\tperl -Ilib t/001-perlcritic.t 2>&1 | less

rawcritic:
\tperlcritic lib script

tidy:
\tperltidy -b -bext='/' \$(shell find lib -name "*.pm") script/arduino_builder

spelling: export EXTENDED_TESTING = 1
spelling:
\t\$(PERLRUN) t/001-spelling.t --interactive

alltest: export EXTENDED_TESTING = 1
alltest: test

clean:: clean_coverdb

clean_coverdb:
\trm -fr cover_db
MAKE_FRAGMENT

  return join "\n", @postamble;
}

# You can add below this template a `postamble` sub that returns more content to
# add to the generated Makefile.

# End of the template. You can add custom content below this line.

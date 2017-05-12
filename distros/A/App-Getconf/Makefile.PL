#!/usr/bin/perl

use warnings;
use strict;
use ExtUtils::MakeMaker;

# ExtUtils::MakeMaker on Debian is a developer release (?!?)
no warnings qw{numeric};

WriteMakefile(
  NAME          => 'App::Getconf',
  AUTHOR        => q{Stanislaw Klekot <cpan@jarowit.net>},
  VERSION_FROM  => 'lib/App/Getconf.pm',
  #ABSTRACT_FROM => 'lib/App/Getconf.pm',
  ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'=> 'perl')
    : ()),
  PREREQ_PM => {
    base          => 0,
    Exporter      => 0,
    Carp          => 0,
    'Tie::IxHash' => 0,
  },
  dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  #clean         => { FILES => 'App-Getconf-*' },
);

sub MY::postamble {
  return <<'EOF'
.PHONY: reltest
reltest: export RELEASE_TESTING=1
reltest: test

.PHONY: tarball
tarball: make reltest
	git archive --format=tar --prefix=$(DISTVNAME)/ v$(VERSION) | gzip -9 > $(DISTVNAME).tar.gz

.PHONY: make
make: Makefile

Makefile: lib/App/Getconf.pm
EOF
}

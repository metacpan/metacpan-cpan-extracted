GIT2CL ?= git2cl
PERL ?= perl
BASH ?= bash

#: Build everything
all: Build
	$(PERL) Build --makefile_env_macros 1

Build:
	$(PERL) Build.PL || $(PERL) Makefile.PL

#: Build program, e.g. copy to blib
build: Build
	$(PERL) Build --makefile_env_macros 1 build

#: Remove automatically generated files
clean: Build
	$(PERL) Build --makefile_env_macros 1 clean

code: Build
	$(PERL) Build --makefile_env_macros 1 code

config_data: BUild
	$(PERL) Build --makefile_env_macros 1 config_data

diff: Build
	$(PERL) Build --makefile_env_macros 1 diff

#: Create distribution tarball
dist: Build
	$(PERL) Build --makefile_env_macros 1 dist

distcheck: Build clean
	$(PERL) Build --makefile_env_macros 1 distcheck

distclean: Build
	$(PERL) Build --makefile_env_macros 1 distclean

distdir: Build
	$(PERL) Build --makefile_env_macros 1 distdir

distmeta: Build
	$(PERL) Build --makefile_env_macros 1 distmeta

distsign: Build
	$(PERL) Build --makefile_env_macros 1 distsign

disttest: Build
	$(PERL) Build --makefile_env_macros 1 disttest

#: Create documentation (in blib/libdoc) via perlpod
docs: Build
	$(PERL) Build --makefile_env_macros 1 docs

fakeinstall: Build
	$(PERL) Build --makefile_env_macros 1 fakeinstall

#: Show help
help: Build
	$(PERL) Build --makefile_env_macros 1 help

html: Build
	$(PERL) Build --makefile_env_macros 1 html

#: Install this puppy
install: Build
	$(PERL) Build --makefile_env_macros 1 install

#: Install other Perl packages that this package needs
installdeps: Build
	$(PERL) Build --makefile_env_macros 1 installdeps

#: Make a MANIFEST file
manifest: Build
	$(PERL) Build --makefile_env_macros 1 manifest

#: Generate manual pages
manpages: Build
	$(PERL) Build --makefile_env_macros 1 manpages

ppd: Build
	$(PERL) Build --makefile_env_macros 1 ppd

ppmdist: Build
	$(PERL) Build --makefile_env_macros 1 ppmdist

prereq_report: Build
	$(PERL) Build --makefile_env_macros 1 prereq_report

pure_install: Build
	$(PERL) Build --makefile_env_macros 1 pure_install

skipcheck:  Build
	$(PERL) Build --makefile_env_macros 1 skipcheck

#: Same as "test". "check" is the usual autoconf name
test check: test-t

#: Run all Test::More tests
test-t: Build
	$(PERL) Build --makefile_env_macros 1 test && $(MAKE) clean

#: Check code coverage
testcover:
	$(PERL) Build --makefile_env_macros 1 testcover

#: Remove change log: ChangeLog
rmChangeLog:
	rm ChangeLog || true

#: Create a ChangeLog from git via git log and git2cl
ChangeLog: rmChangeLog
	git log --pretty --numstat --summary | $(GIT2CL) >$@

#: Calling perl debugger (perldb) on each test
testdb:
	$(PERL) Build --makefile_env_macros 1 testdb

testpod:
	$(PERL) Build --makefile_env_macros 1 testpod

testpodcoverage:
	$(PERL) Build --makefile_env_macros 1 testpodcoverage

versioninstall:
	$(PERL) Build --makefile_env_macros 1 versioninstall

.EXPORT: INC PREFIX DESTDIR VERBINST INSTALLDIRS TEST_VERBOSE LIB UNINST INSTALL_BASE POLLUTE

.PHONY: all realclean build clean check test testcover testdb testpod testpodcoverage

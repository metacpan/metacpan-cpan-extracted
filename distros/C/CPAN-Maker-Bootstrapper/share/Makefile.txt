#-*- mode: makefile; -*-
# To see available targets"
# make help

SHELL := /bin/bash

.SHELLFLAGS := -e -o pipefail -c

# this the user's version from their VERSION file
VERSION := $(shell test -e VERSION || echo 1.0.0 > VERSION; cat VERSION)

PACKAGE_VERSION = $(VERSION)

lc = $(shell printf '%s' '$(1)' | tr '[:upper:]' '[:lower:]')

# this is the current version in your Perl path (but not necessarily the version that produced this Makefile)
BOOTSTRAPPER_VERSION := $(shell perl -MCPAN::Maker::Bootstrapper -e 'print CPAN::Maker::Bootstrapper->VERSION;' 2>/dev/null || true) 

config.mk: ;

-include config.mk

ifeq ($(origin MODULE_NAME),undefined)
  MODULE_NAME := $(shell SOURCE=$$(pwd) perl -MCwd=abs_path -MFile::Basename=basename \
    -e '$$m=basename(abs_path($$ENV{SOURCE})); $$m =~s/\-/::/g; print $$m')
endif

export MODULE_NAME PACKAGE_VERSION

MODULE_PATH     = lib/$(shell echo $(MODULE_NAME) | perl -npe 's/::/\//g;').pm
PROJECT_NAME   ?= $(shell echo $(MODULE_NAME) | sed -e 's/::/-/g;')
UNIT_TEST_NAME  = $(shell TEST_NAME=$(PROJECT_NAME) perl -e 'printf q{t/00-%s.t}, lc $$ENV{TEST_NAME}')

CMB_UPDATE_CHECK  ?= on
CMB_VERSION_DRIFT ?= fail

DARKPAN_REQUIRES ?=
DARKPAN_URL ?=

export DARKPAN_URL

LOG_LEVEL ?= info

NO_ECHO ?= @
NO_COLOR ?=

TARBALL_ORDER_ONLY_PREREQS ?=


BOOTSTRAPPER   := $(shell command -v cmb)
DOCKER         := $(shell command -v docker)
GIT            := $(shell command -v git)
CPAN_MAKER     := $(shell command -v cpan-maker)
MD_UTILS       := $(shell command -v markdown-render)
POD2MARKDOWN   := $(shell command -v pod2markdown)
PODEXTRACT     := $(shell command -v podextract)
SCANDEPS       := $(shell command -v scandeps-static)
GITHUB_ACTIONS := $(shell command -v gha-aws)
CPM            := $(shell command -v cpm)
CARTON         := $(shell command -v carton)

CPAN_INSTALLER ?= $(firstword $(CPM) $(CARTON))

ifeq ($(CPAN_INSTALLER),)
  $(warning no cpm/carton found -- set SYNTAX_CHECKING=off if builds fail to find dependencies)
endif

ifeq ($(MD_UTILS),)
    $(warning Markdown::Render is not installed - run: cpanm Markdown::Render to generate .md files from pod)
endif


GIT_NAME     ?= $(shell $(GIT) config --global user.name 2>/dev/null || echo "Anonymouse")
GIT_EMAIL    ?= $(shell $(GIT) config --global user.email 2>/dev/null || echo "anonymouse@example.org")
GITHUB_USER  ?= $(shell $(GIT) config --global user.github 2>/dev/null || echo "anonymouse")

GIT_SHA      := $(shell $(GIT) rev-parse HEAD 2>/dev/null || echo 'unknown' )
GIT_DIRTY    := $(shell $(GIT) describe --always --dirty --abbrev=40 2>/dev/null || echo 'unknown')

CONFIG_READER = CPAN::Maker::Bootstrapper::ConfigReader

BASEDIR  ?= $(shell perl -M$(CONFIG_READER) -e 'print $(CONFIG_READER)->new("$(CONFIG)")->cpan_maker_basedir;')

MIN_PERL_VERSION ?= 5.010

MIN_PERL_VERSION_FLAG := $(shell v=$$(test -e buildspec.yml && dnk get .min-perl-version < buildspec.yml 2>/dev/null); [[ -n "$$v" ]] && echo "-m $$v")

ifeq ($(SCANDEPS),)
  SCAN = OFF
else
  SCAN ?= ON
endif

scan_on := $(filter on,$(call lc,$(SCAN)))

cmb_update_check  := $(call lc,$(CMB_UPDATE_CHECK))
cmb_version_drift := $(call lc,$(CMB_VERSION_DRIFT))

ifeq ($(BOOTSTRAPPER),)
  $(error CPAN::Maker::Bootstrapper not installed - run cpanm CPAN::Maker::Bootstrapper)
endif

define find-files
$(1) := $(patsubst %.in,%,$(shell for d in $(2); do test -d "$$d" && \
  find "$$d" -type f \( -name "$(3)" $(if $(4),-o -name "$(4)") \) \
    ! -name '#*' ! -name '.#*' ! -name '*~' ! -name '*.bak' ; \
done | sort))
endef

$(eval $(call find-files,PERL_MODULES,lib,*.pm.in))

ifeq ($(strip $(PERL_MODULES)),)
ifneq ($(strip $(MODULE_PATH)),)
PERL_MODULES := $(MODULE_PATH)
endif
endif

$(eval $(call find-files,BIN_FILES,bin,*.in))
$(eval $(call find-files,TESTS,t,*.t,*.p[ml]))
$(eval $(call find-files,SOURCE_FILES,lib bin,*.p[ml].in))

SOURCE_FILES_IN := $(addsuffix .in,$(SOURCE_FILES))

POD_MODULES = $(PERL_MODULES:.pm=.pod)

TARBALL = $(PROJECT_NAME)-$(VERSION).tar.gz

DEPS += \
    buildspec.yml \
    README.md \
    $(MODULE_PATH).in \
    $(PERL_MODULES) \
    $(BIN_FILES) \
    requires \
    recommends \
    suggests \
    cpanfile \
    test-requires \
    $(UNIT_TEST_NAME) \
    ChangeLog

.DEFAULT_GOAL := $(TARBALL)

.PHONY: all
all: $(TARBALL)

PACKAGE_VERSION = $(VERSION)

GIT_USER := $(GITHUB_USER)

TEMPLATE_VARS += \
    PACKAGE_VERSION \
    MODULE_NAME \
    GIT_SHA \
    GIT_DIRTY \
    GIT_EMAIL \
    GIT_USER \
    GIT_NAME \
    MIN_PERL_VERSION \
    PROJECT_NAME \

-include .includes/local.mk

include .includes/perl.mk

bin/%.sh: bin/%.sh.in
	$(call gen-vars-file,$<.vars)
	$(NO_ECHO)trap 'rm -f $<.vars' EXIT; \
	$(BOOTSTRAPPER) resolve-vars $< $(TEMPLATE_VARS)  > $@; \
	chmod +x $@

bin/%: bin/%.in
	$(call gen-vars-file,$<.vars)
	$(NO_ECHO)trap 'rm -f $<.vars' EXIT; \
	$(BOOTSTRAPPER) resolve-vars $< $(TEMPLATE_VARS) > $@; \
	chmod +x $@

.PHONY: quick
quick: ## turns off scanning, perltidy, perlcritic
	$(NO_ECHO)$(MAKE) SCAN=off LINT=off

-include .includes/bootstrap.mk

cpanfile.runtime: requires
	$(NO_ECHO)$(CPAN_MAKER) create-cpanfile \
	  --dependency-type requires $< -o $@

cpanfile.requires: requires test-requires
	$(NO_ECHO)$(CPAN_MAKER) create-cpanfile --dependency-type requires $+ -o $@;

cpanfile.suggests: suggests
	$(NO_ECHO)$(CPAN_MAKER) create-cpanfile --dependency-type suggests $< -o $@;

cpanfile.recommends: recommends
	$(NO_ECHO)$(CPAN_MAKER) create-cpanfile --dependency-type recommends $< -o $@;

cpanfile: cpanfile.requires cpanfile.suggests cpanfile.recommends 
	$(NO_ECHO)rm -f $@; \
	for a in $+; do \
	  cat $$a >>$@; \
	done

ifeq ($(darkpan_requires_on),1)

ifeq ($(strip $(DARKPAN_URL)),)
$(error DARKPAN_URL must be set when DARKPAN_REQUIRES is enabled)
endif

DEPS += cpanfile.darkpan cpanm.darkpan

cpanfile.darkpan cpanm.darkpan: requires $(wildcard darkpan.skip)
	$(NO_ECHO)if [[ -e darkpan.skip ]]; then \
	  filter="--filter darkpan.skip"; \
	fi; \
	$(BOOTSTRAPPER) create-darkpan-requires $$filter $<; \
	$(BOOTSTRAPPER) extra-files . cpanfile.darkpan cpanm.darkpan
endif

$(TARBALL): $(DEPS) | update-available $(TARBALL_ORDER_ONLY_PREREQS) \
    $(if $(syntax_on), $(PERL_CHECKED_FILES) $(PERL_BIN_CHECKED_FILES)) \
    $(if $(tidy_on), $(PERL_MODULES:%=%.tdy) $(PERL_BIN_FILES:%=%.tdy)) \
    $(if $(critic_on), $(PERL_MODULES:%=%.crit) $(PERL_BIN_FILES:%=%.crit))
	$(NO_ECHO)if [[ -z "$(NO_COLOR)" ]]; then \
	  COLOR='--color'; \
	fi; \
	if [[ -n "$$SKIP_TESTS" ]]; then \
	  SKIP_TESTS="--skip-tests"; \
	fi; \
	PERL5LIB=$$(pwd)/local/lib/perl5:$$PERL5LIB \
	  $(CPAN_MAKER) $$SKIP_TESTS -l $(LOG_LEVEL) $$COLOR -b $<

$(dir $(MODULE_PATH)):
	$(NO_ECHO)mkdir -p $@

$(MODULE_PATH).in: | $(dir $(MODULE_PATH))
	$(NO_ECHO)mkdir -p $$(dirname $@)
	$(call gen-vars-file,$@.vars)
	$(NO_ECHO)tmpl=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{class-module.pm.tmpl})' 2>/dev/null); \
	[[ -n "$(STUB)" ]] && tmpl="$(STUB)"; \
	trap 'rm -f $@.vars' EXIT; \
	$(BOOTSTRAPPER) resolve-vars "$$tmpl" $(TEMPLATE_VARS) > $@

test.t.tmpl:
	$(NO_ECHO)template=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{$@});' 2>/dev/null || true); \
	if [[ -n "$$template" ]]; then \
	  cp $$template $@; \
	else \
	  touch $@; \
	fi; \
	chmod 0644 $@

$(UNIT_TEST_NAME): | test.t.tmpl
	$(call gen-vars-file,$<.vars)
	$(NO_ECHO)trap 'rm -f $<.vars' EXIT; \
	$(BOOTSTRAPPER) resolve-vars test.t.tmpl $(TEMPLATE_VARS) > $@

ifeq ($(wildcard README.md.in),)
# If README.md.in does NOT exist, use POD2MARKDOWN on the module
README.md: $(MODULE_PATH)
	$(NO_ECHO)if [[ -z "$(MD_UTILS)" ]] || [[ -z "$(POD2MARKDOWN)" ]]; then \
	  echo "WARNING: install Markdown::Render and Pod::Markdown to generate .md files from pod"; \
	else  \
	  tmpfile=$$(mktemp); \
	  trap 'rm -f $$tmpfile' EXIT; \
	  echo "@TOC@" > $$tmpfile; \
	  $(POD2MARKDOWN) $< >> $$tmpfile; \
	  $(MD_UTILS) $$tmpfile > $@ || true; \
	fi
else
# If README.md.in DOES exist, use MD_UTILS on the template
README.md: README.md.in
	$(NO_ECHO)if [[ -z "$(MD_UTILS)" ]]; then \
	  echo "WARNING: install Markdown::Render to generate .md files"; \
	  cp $< $@; \
	else \
	  $(MD_UTILS) $< > $@; \
	fi
endif

-include .includes/modulino.mk

-include .includes/bash-completion.mk

ifneq ($(scan_on),)
requires.raw recommends.raw suggests.raw &: $(SOURCE_FILES_IN) ## single scan producing all three library dependency tiers
	$(NO_ECHO)printf '%s\n' $(SOURCE_FILES_IN) > file_list.tmp; \
	PERL5LIB=lib:local/lib/perl5:$$PERL5LIB $(SCANDEPS) $(MIN_PERL_VERSION_FLAG) \
	  --raw \
	  --file-list file_list.tmp \
	  --no-core --filter \
	  --requires-file requires.raw \
	  --recommends-file recommends.raw \
	  --suggests-file suggests.raw > /dev/null; \
	rm -f file_list.tmp

provides: $(addsuffix .in,$(PERL_MODULES))
	$(NO_ECHO)$(BOOTSTRAPPER) provides >$@

test-requires.scan: $(TESTS)
	$(NO_ECHO)printf '%s\n' $(TESTS) > file_list.tmp; \
	tmp=$$(mktemp); trap 'rm -f $$tmp' EXIT; \
	PERL5LIB=lib:local/lib/perl5:$$PERL5LIB $(SCANDEPS) $(MIN_PERL_VERSION_FLAG) \
	  --raw \
	  --file-list file_list.tmp \
	  --no-core --filter \
	  --requires-file $$tmp > /dev/null; \
	perl -npe 'while(s/  / /g) {}' < $$tmp | sort > $@; \
	rm -f file_list.tmp

test-requires.raw: test-requires.scan
	$(NO_ECHO)sed -e 's/ 0$$/ undef/g' $< > $@

test-requires: test-requires.raw provides ## creates or updates the `test-requires` file used to populate the TEST_REQUIRES section of the Makefile.PL
	$(NO_ECHO)cleanfiles="$@.xxx"; \
	reconciled=$$(mktemp); \
	filtered=$$(mktemp); \
	trap 'rm -f $$cleanfiles $$reconciled $$filtered' EXIT; \
	if test -e "$@"; then \
	  cp "$@" "$@.xxx"; \
	fi; \
	$(BOOTSTRAPPER) filter "$<" "$@.skip" "$@.xxx" > "$$reconciled"; \
	$(BOOTSTRAPPER) deps-filter "$$reconciled" > "$$filtered"; \
	awk 'NR == FNR { provided[$$1] = 1; next } !provided[$$1]' \
	  provides "$$filtered" > "$@"; \
	if test ! -e "$@" || ! cmp -s "$$output" "$@"; then \
	  if test -n "$$output"; then  \
	    mv "$$output" "$@"; \
	  fi; \
	fi


requires: ## creates or updates the `requires` file used to populate PREQ_PM section of the Makefile.PL

recommends: ## creates or updates the `recommends` file (soft, non-eval conditional dependencies)

suggests: ## creates or updates the `suggests` file (eval-wrapped, optional dependencies)

requires recommends suggests: %: %.reconciled
	@:

requires.reconciled recommends.reconciled suggests.reconciled: %.reconciled: %.raw
	$(NO_ECHO)cleanfiles="$*.xxx"; \
	reconciled=$$(mktemp); \
	filtered=$$(mktemp); \
	trap 'rm -f $$cleanfiles $$reconciled $$filtered' EXIT; \
	if test -e "$*"; then \
	  cp "$*" "$*.xxx"; \
	fi; \
	$(BOOTSTRAPPER) filter "$*.raw" "$*.skip" "$*.xxx" > "$$reconciled"; \
	$(BOOTSTRAPPER) deps-filter "$$reconciled" > "$$filtered"; \
	if test ! -e "$*" || ! cmp -s "$$filtered" "$*"; then \
	  mv "$$filtered" "$*"; \
	fi; \
	touch "$@"

else

requires recommends suggests test-requires:
	$(NO_ECHO)test -e $@ || { \
	  echo "ERROR: $@ does not exist and distribution dependency scanning is disabled (SCAN=OFF)" >&2; \
	  exit 1; \
	}

endif


ChangeLog:
	$(NO_ECHO)test -e $@ || touch $@

buildspec.yml.tmpl:
	$(NO_ECHO)template=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{$@});' 2>/dev/null || true); \
	if [[ -n "$$template" ]]; then \
	  cp $$template $@; \
	else \
	  touch $@; \
	fi; \
	chmod 0644 $@

buildspec.yml: | buildspec.yml.tmpl
	$(call gen-vars-file,buildspec.yml.tmpl.vars)
	$(NO_ECHO)buildspec=$$(mktemp); \
	trap 'rm -f buildspec.yml.tmpl.vars' EXIT; \
	specfile="$(PROJECT_NAME)"; \
	specfile="$${specfile,,}.yml"; \
	if [[ -e "$$specfile" ]]; then \
	  share_files="    - $$specfile\n"; \
	fi; \
	SHARE_FILES="$$share_files" $(BOOTSTRAPPER) resolve-vars buildspec.yml.tmpl > $$buildspec; \
	if test -e resources.yml; then \
	  cat resources.yml >> $$buildspec; \
	  rm resources.yml; \
	fi; \
	cp $$buildspec $@; \
	chmod 0644 $@

include .includes/git.mk
include .includes/help.mk
include .includes/release-notes.mk
include .includes/update.mk
include .includes/upgrade.mk
include .includes/version.mk

GENERATED_FILES += \
    provides \
    test-requires.scan

CLEANFILES += \
    $(BIN_FILES) \
    $(PERL_MODULES) \
    $(POD_MODULES) \
    $(GENERATED_FILES) \
    *.tar.gz \
    *.tmp \
    *.xxx \
    *.raw \
    *.reconciled \
    extra-files \
    extra-files.mk \
    module.pm.tmpl \
    release-*.{lst,diffs} \
    cpanfile.recommends \
    cpanfile.requires \
    cpanfile.runtime \
    cpanfile.suggests

.PHONY: clean-local
clean-local::

clean: clean-local ## removes temporary build artifacts
	$(NO_ECHO)rm -f $(CLEANFILES)

.PHONY: basedir
basedir:
	$(NO_ECHO)echo $(BASEDIR)


GSOURCE_FILES = $(SOURCE_FILES:.in=)

.PHONY: package
package: clean ## run lint & scan
	$(MAKE) LINT=on SCAN=on

# we want to trigger a rebuild of the tarball if any changes is made
# to our files being added to the distribition (non-source) either in
# the root of the tarball or in the share directory.
# 'extra-files' is created by cpan-maker from buildspec.yml
#
# this recipe will then add a new file to be included
# extra-files.mk. Now whenever buildspec.yml changes we'll get a new
# extra-files.mk

# extra-files.mk:  $(TARBALL): share/foo.tpl share/bar.tpl 
# git ls-files will ensure that we have added artifacts to repo

extra-files: buildspec.yml
	$(NO_ECHO)$(BOOTSTRAPPER) extra-files > $@.tmp; \
	if test -f extra-files.skip; then \
	  awk '!/^[[:space:]]*(#|$$)/ { print $$1 }' extra-files.skip > $@.skip.tmp; \
	else \
	  : > $@.skip.tmp; \
	fi; \
	if [[ -d .git ]] && [[ -n "$(GIT)" ]]; then \
	  for a in $$(awk '{print $$1}' $@.tmp); do \
	    grep -Fqx -- "$$a" $@.skip.tmp && continue; \
	    $(GIT) ls-files --error-unmatch -- "$$a" >/dev/null; \
	  done; \
	fi; \
	rm -f $@.skip.tmp; \
	mv $@.tmp $@

extra-files.mk: extra-files
	$(NO_ECHO)printf '$$(TARBALL): %s\n' \
	  "$$(awk 'NF{print $$1}' $< | tr '\n' ' ')" > $@

ifeq ($(BOOTSTRAP_BUILD),)
include extra-files.mk
endif

include .includes/publish.mk

include .includes/builder.mk

include .includes/test.mk

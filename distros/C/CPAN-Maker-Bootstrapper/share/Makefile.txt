#-*- mode: makefile; -*-
# To see available targets"
# make help

SHELL := /bin/bash

.SHELLFLAGS := -ec

# this the user's version from their VERSION file
VERSION := $(shell test -e VERSION || echo 1.0.0 > VERSION; cat VERSION)

# this is the current version in your Perl path (but not necessarily the version that produced this Makefile)
BOOTSTRAPPER_VERSION := $(shell perl -MCPAN::Maker::Bootstrapper -e 'print CPAN::Maker::Bootstrapper->VERSION;' 2>/dev/null || true) 

config.mk: ;

-include config.mk

MODULE_NAME  ?= $(shell SOURCE=$$(pwd) perl -MCwd=abs_path -MFile::Basename=basename -e '$$m=basename(abs_path($$ENV{SOURCE})); $$m =~s/\-/::/g; print $$m')

MODULE_PATH = lib/$(shell echo $(MODULE_NAME) | perl -npe 's/::/\//g;').pm

PROJECT_NAME ?= $(shell echo $(MODULE_NAME) | sed -e 's/::/-/g;')

LOG_LEVEL ?= info

NO_ECHO ?= @
NO_COLOR ?=

UNIT_TEST_NAME = $(shell TEST_NAME=$(PROJECT_NAME) perl -e 'printf q{t/00-%s.t}, lc $$ENV{TEST_NAME}')

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

CMB_UPDATE_CHECK  ?= on
CMB_VERSION_DRIFT ?= fail

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

ifeq ($(BOOTSTRAPPER),)
  $(error CPAN::Maker::Bootstrapper not installed - run cpanm CPAN::Maker::Bootstrapper)
endif

define find-files
$(1) := $(patsubst %.in,%,$(shell for d in $(2); do test -d "$$d" && \
  find "$$d" -type f -name "$(3)" \
    ! -name '#*' ! -name '.#*' ! -name '*~' ! -name '*.bak' ; \
done | sort))
endef

$(eval $(call find-files,PERL_MODULES,lib,*.pm.in))
$(eval $(call find-files,BIN_FILES,bin,*.in))
$(eval $(call find-files,TESTS,t,*.t))
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
    local \
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
quick: ## quick build, turns off scanning, perltidy, perlcritic
	$(NO_ECHO)$(MAKE) SCAN=off LINT=off

.INTERMEDIATE: cpanfile.requires cpanfile.suggests cpanfile.recommends

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

$(TARBALL): $(DEPS) | update-available \
    $(if $(tidy_on), $(PERL_MODULES:%=%.tdy) $(PERL_BIN_FILES:%=%.tdy)) \
    $(if $(critic_on), $(PERL_MODULES:%=%.crit) $(PERL_BIN_FILES:%=%.crit))
	$(NO_ECHO)if [[ -z "$(NO_COLOR)" ]]; then \
	  COLOR='--color'; \
	fi; \
	if [[ -n "$$SKIP_TESTS" ]]; then \
	  SKIP_TESTS="--skip-tests"; \
	fi; \
	$(CPAN_MAKER) $$SKIP_TESTS -l $(LOG_LEVEL) $$COLOR -b $<

$(MODULE_PATH).in:
	$(NO_ECHO)tmpl=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{class-module.pm.tmpl})' 2>/dev/null); \
	[[ -n "$(STUB)" ]] && tmpl="$(STUB)"; \
	$(call gen-vars-file,$@.vars); \
	trap 'rm -f $@.vars' EXIT; \
	mkdir -p $$(dirname $@); \
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

.INTERMEDIATE: requires.raw recommends.raw suggests.raw test-requires.raw

requires.raw recommends.raw suggests.raw &: $(SOURCE_FILES_IN) ## single scan producing all three library dependency tiers
	$(NO_ECHO)printf '%s\n' $(SOURCE_FILES_IN) > file_list.tmp; \
	$(SCANDEPS) $(MIN_PERL_VERSION_FLAG) \
	  --raw \
	  --file-list file_list.tmp \
	  --no-core --filter \
	  --requires-file requires.raw \
	  --recommends-file recommends.raw \
	  --suggests-file suggests.raw > /dev/null; \
	rm -f file_list.tmp

test-requires.raw: $(TESTS) ## scan of t/ for test-only dependencies (requires tier only)
	$(NO_ECHO)printf '%s\n' $(TESTS) > file_list.tmp; \
	$(SCANDEPS) $(MIN_PERL_VERSION_FLAG) --raw --file-list file_list.tmp --no-core --filter \
	  --requires-file test-requires.raw > /dev/null; \
	rm -f file_list.tmp

# shared by requires, recommends, suggests, and test-requires: reconciles
# a fresh scan (%.raw) against history (skip list + previous run), via
# `cmb filter`, the same skip/pin/preserve logic used since the
# bash-script era. Only runs when SCAN=on; otherwise the target is left
# untouched (whatever's already on disk, or nothing on a fresh checkout).
%: %.raw
	$(NO_ECHO)cleanfiles="$@.xxx"; \
	trap 'rm -f $$cleanfiles' EXIT; \
	scan="$(SCAN)"; \
	if [[ "$${scan^^}" = "ON" ]]; then \
	  if test -e "$@"; then \
	    cp "$@" "$@.xxx"; \
	  fi; \
	  cmb filter "$<" "$@.skip" "$@.xxx" > $@; \
	fi

requires: $(SOURCE_FILES_IN) ## creates or updates the `requires` file used to populate PREQ_PM section of the Makefile.PL

test-requires: $(TESTS) ## creates or update the `test-requires` file used to populate the TEST_REQUIRES section of the Makefile.PL

recommends: $(SOURCE_FILES_IN) ## creates or updates the `recommends` file (soft, non-eval conditional dependencies)

suggests: $(SOURCE_FILES_IN) ## creates or updates the `suggests` file (eval-wrapped, optional dependencies)

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

CLEANFILES += \
    $(BIN_FILES) \
    $(PERL_MODULES) \
    $(POD_MODULES) \
    *.tar.gz \
    *.tmp \
    *.xxx \
    *.raw \
    extra-files \
    extra-files.mk \
    provides \
    module.pm.tmpl \
    release-*.{lst,diffs} \
    cmb_md5sums.txt

.PHONY: clean-local
clean-local::

clean: clean-local ## removes temporary build artifacts
	$(NO_ECHO)rm -f $(CLEANFILES)

.PHONY: basedir
basedir:
	$(NO_ECHO)echo $(BASEDIR)

.PHONY: workflow
workflow:
	$(NO_ECHO)dist_dir=$$(perl -MFile::ShareDir=dist_dir -e 'print dist_dir(q{CPAN-Maker-Bootstrapper});' 2>/dev/null || true); \
	if [[ -z "$$dist_dir" ]]; then \
	  echo >&2 "ERROR: could not determine CPAN::Maker::Bootstrapper share directory"; \
	  exit 1; \
	fi; \
	pwd=$$(pwd); \
	cp $$dist_dir/builder $$pwd; \
	chmod +x $$pwd/builder; \
	build_requires="$$(mktemp)"; trap 'rm -f $$build_requires' EXIT; \
	test -e build-requires || touch build-requires; \
	cp build-requires $$build_requires; \
	cat $$dist_dir/build-requires >>$$build_requires; \
	sort -u $$build_requires > build-requires; \
	mkdir -p $$pwd/.github/workflows; \
	project_name="$(PROJECT_NAME)"; \
	project_name="$${project_name,,}"; \
	sed -e 's/CPAN::Maker::Bootstrapper/$(PROJECT_NAME)/' \
	    -e "s/cpan-maker-bootstrapper/$$project_name/" $$dist_dir/build.yml > $$pwd/.github/workflows/build.yml; \
	echo "** Installed build-requires, builder, .github/workflows/build.yml"; \
	echo "** Add to your repo:"; \
	echo "git add build-requires builder .github/workflows/build.yml"

DOCKER_BUILD_IMAGE    ?= debian:trixie
BRANCH                ?= $(shell git branch --show-current)
BUILDER               ?= builder
BUILD_LOG             ?= $(shell echo "build-$$(date +'%Y%m%d%H%M%S').log")
DOCKER_CPAN_INSTALLER ?= cpm

.PHONY: build-ci
build-ci:
	@test -n "$(DOCKER)" || (echo "docker unavailable: install docker or set DOCKER" && exit 1); \
	test -x "$$(pwd)/$(BUILDER)" || (echo "no builder. set BUILDER or run make workflow to install builder" && exit 1); \
	repo_url="https://github.com/$(GITHUB_USER)/$(PROJECT_NAME).git"; \
	start_time=$$(date +%s); \
	$(DOCKER) run --rm \
	  -v "$$(pwd)/$(BUILDER):/builder:ro" \
	  -v "$$(pwd):/$$(basename $$(pwd))" \
	  -e GITHUB_REF_NAME=$(BRANCH) \
	  -e INSTALLER=$(DOCKER_CPAN_INSTALLER) \
	  -e REPO=$$(basename  -s .git "$$(git remote get-url origin)") \
	  $(DOCKER_BUILD_IMAGE) /builder "$$repo_url" 2>&1 | tee $(BUILD_LOG); \
	end_time=$$(date +%s); \
	total_time=$$(($$end_time - $$start_time)); \
	echo "Build time: $$(date -u -d @$$total_time +%T)" >> $(BUILD_LOG); \
	ln -sf $(BUILD_LOG) build.log; \
	echo "See build.log"

GSOURCE_FILES = $(SOURCE_FILES:.in=)

test: $(GSOURCE_FILES) ## run unit tests
	prove -I lib -v t/

check: $(GSOURCE_FILES) ## syntax check and create source from .in file

# deps.mk depends on SOURCE (.pm.in), not the built .pm targets.
# cmb create-deps already scans .pm.in directly, so this makes deps.mk
# regenerate purely from source edits -- no build artifacts involved,
# so there's no chicken-and-egg with $(PERL_MODULES) needing to be
# built before deps.mk can be regenerated, and 'make clean' can never
# trigger a rebuild through this include (clean doesn't touch .pm.in).
deps.mk: $(SOURCE_FILES_IN)
	$(NO_ECHO)cmb create-deps > $@.tmp && test -s $@.tmp && mv $@.tmp $@ || { rm -f $@.tmp; false; }

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

extra-files.mk: buildspec.yml
	$(NO_ECHO)if [[ -e extra-files ]]; then \
	  printf '$$(TARBALL): %s\n' "$$(awk 'NF{print $$1}' extra-files | tr '\n' ' ')" > $@; \
	else \
	  : > $@; \
	fi

-include extra-files.mk

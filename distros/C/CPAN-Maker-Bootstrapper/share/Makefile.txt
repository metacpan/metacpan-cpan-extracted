#-*- mode: makefile; -*-
# To see available targets"
# make help

SHELL := /bin/bash

.SHELLFLAGS := -ec

VERSION := $(shell test -e VERSION || echo 1.0.0 > VERSION; cat VERSION)

BOOTSTRAPPER_VERSION := $(shell perl -MCPAN::Maker::Bootstrapper -e 'print $$CPAN::Maker::Bootstrapper::VERSION;' 2>/dev/null || true) 

-include config.mk

MODULE_NAME  ?= $(shell SOURCE=$$(pwd) perl -MCwd=abs_path -MFile::Basename=basename -e '$$m=basename(abs_path($$ENV{SOURCE})); $$m =~s/\-/::/g; print $$m')

MODULE_PATH = lib/$(shell echo $(MODULE_NAME) | perl -npe 's/::/\//g;').pm

PROJECT_NAME ?= $(shell echo $(MODULE_NAME) | sed -e 's/::/-/g;')

LOG_LEVEL ?= info

NO_ECHO ?= @

UNIT_TEST_NAME = $(shell TEST_NAME=$(PROJECT_NAME) perl -e 'printf q{t/00-%s.t}, lc $$ENV{TEST_NAME}')

BOOTSTRAPPER   := $(shell command -v bootstrapper)
DOCKER         := $(shell command -v docker)
GIT            := $(shell command -v git)
CPAN_MAKER     := $(shell command -v cpan-maker)
MD_UTILS       := $(shell command -v md-utils.pl)
POD2MARKDOWN   := $(shell command -v pod2markdown)
PODEXTRACT     := $(shell command -v podextract)
SCANDEPS       := $(shell command -v scandeps-static.pl)

ifeq ($(MD_UTILS),)
    $(warning Markdown::Render is not installed - run: cpanm Markdown::Render to generate .md files from pod)
endif

GIT_NAME     ?= $(shell $(GIT) config --global user.name 2>/dev/null || echo "Anonymouse")
GIT_EMAIL    ?= $(shell $(GIT) config --global user.email 2>/dev/null || echo "anonymouse@example.org")
GITHUB_USER  ?= $(shell $(GIT) config --global user.github 2>/dev/null || echo "anonymouse")

CONFIG_READER = CPAN::Maker::Bootstrapper::ConfigReader

BASEDIR  ?= $(shell perl -M$(CONFIG_READER) -e 'print $(CONFIG_READER)->new("$(CONFIG)")->cpan_maker_basedir;')

MIN_PERL_VERSION ?= 5.010

ifeq ($(SCANDEPS),)
  SCAN = OFF
else
  SCAN ?= ON
endif

ifeq ($(BOOTSTRAPPER),)
  $(error CPAN::Maker::Bootstrapper not installed - run cpanm CPAN::Maker::Bootstrapper)
endif

define find-files
$(1) := $(patsubst %.in,%,$(shell for d in $(2); do test -d "$$d" && find $$d -type f -name "$(3)"; done))
endef

$(eval $(call find-files,PERL_MODULES,lib,*.pm.in))
$(eval $(call find-files,BIN_FILES,bin,*.in))
$(eval $(call find-files,TESTS,t,*.t))
$(eval $(call find-files,SOURCE_FILES,lib bin,*.p[ml].in))

POD_MODULES = $(PERL_MODULES:.pm=.pod)

TARBALL = $(PROJECT_NAME)-$(VERSION).tar.gz

DEPS = \
    buildspec.yml \
    README.md \
    $(MODULE_PATH).in \
    $(PERL_MODULES) \
    $(BIN_FILES) \
    requires \
    cpanfile \
    test-requires \
    $(UNIT_TEST_NAME) \
    ChangeLog

.DEFAULT_GOAL := $(TARBALL)

all: update-available 

include .includes/perl.mk

bin/%.sh: bin/%.sh.in
	$(NO_ECHO)sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' \
	    -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' < $< > $@; \
	chmod +x $@

bin/%: bin/%.in
	$(NO_ECHO)sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' \
	    -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' < $< > $@; \
	chmod +x $@

.PHONY: quick
quick: ## quick build, turns off scanning, perltidy, perlcritic
	$(NO_ECHO)$(MAKE) SCAN=off LINT=off

cpanfile: requires test-requires 
	$(NO_ECHO)if [[ -e requires ]] && [[ -e test-requires ]]; then \
	  $(CPAN_MAKER) create-cpanfile test-requires requires -o $@; \
	else \
	  echo >&2 "ERROR: make sure SCAN=on to produce requires, test-requires"; \
	fi

$(TARBALL): $(DEPS) \
    $(if $(tidy_on), $(PERL_MODULES:%=%.tdy) $(PERL_BIN_FILES:%=%.tdy)) \
    $(if $(critic_on), $(PERL_MODULES:%=%.crit) $(PERL_BIN_FILES:%=%.crit))
	$(CPAN_MAKER) -l $(LOG_LEVEL) -b $<

module.pm.tmpl:
	$(NO_ECHO)if [[ -n "$(STUB)" ]]; then \
	  cp --preserve=all --update=none $(STUB) $@; \
	  chmod +w $@; \
	else \
	  template=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{class-module.pm.tmpl});' 2>/dev/null || true); \
	  chmod -f 644 $@ || true; \
	  touch $@; \
	fi

$(MODULE_PATH).in: module.pm.tmpl
	$(NO_ECHO)mkdir -p $$(dirname $@); \
	test -e $@ || sed -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' \
	    -e 's/[@]GIT_NAME[@]/$(GIT_NAME)/' \
	    -e 's/[@]GIT_EMAIL[@]/$(GIT_EMAIL)/' < $< > $@; \
	rm $<

test.t.tmpl:
	$(NO_ECHO)template=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{$@});' 2>/dev/null || true); \
	if [[ -n "$$template" ]]; then \
	  cp $$template $@; \
	else \
	  touch $@; \
	fi; \
	chmod 0644 $@

$(UNIT_TEST_NAME): | test.t.tmpl
	$(NO_ECHO)sed -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' < test.t.tmpl > $@

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
	  $(MD_UTILS) $$tmpfile > $@; \
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

modulino.tmpl:
	$(NO_ECHO)modulino_path=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{modulino.tmpl});' 2>/dev/null); \
	cp $$modulino_path $@

.PHONY: modulino
modulino: modulino.tmpl ## creates a bash script that calls your modulino (MODULE_NAME=module ALIAS=name)
	$(NO_ECHO)trap 'rm -f modulino.tmpl' EXIT; \
	MODULE_NAME="$(MODULE_NAME)"; \
	ALIAS="$${ALIAS:-$$MODULE_NAME}"; \
	binfile=$$(echo "$$ALIAS" | perl -npe 's/::/\-/g;'); \
	modulino="bin/$${binfile,,}"; \
	sed -e "s/[@]MODULE_NAME[@]/$$MODULE_NAME/" \
	    -e "s/[@]ALIAS[@]/$$ALIAS/" $< > "$${modulino}.in"; \
	test -e .gitignore && { grep -q "$$modulino" .gitignore || echo "$$modulino" >> .gitignore; }; \
	echo "$$modulino"

define scan-deps
	dep_requires=$$(mktemp); \
	packages=$$(mktemp); \
	cleanfiles="$$cleanfiles $$dep_requires $$packages $(1).tmp"; \
	min_perl_version=$$(perl -MYAML::Tiny=LoadFile -e 'print LoadFile(q{buildspec.yml})->{q{min-perl-version}};'); \
	if [[ -n "$$min_perl_version" ]]; then \
	  min_perl_version="-m $$min_perl_version"; \
	fi; \
	for d in $(2); do \
	  for a in $$(find $$d -name "$(3)"); do \
	    perl -ne 'print "$$1\n" if /^package +(.*?);/' $$a >> $$packages; \
	    echo >&2 "Scanning...$$a"; \
	    $(SCANDEPS) -r $$min_perl_version --no-core $$a | awk '{printf "%s %s\n", $$1,$$2}' >> $$dep_requires; \
	  done; \
	done; \
	if test -s "$$dep_requires"; then \
	  sort -u $$dep_requires > $(1).tmp; \
	  grep -vFf "$$packages" "$(1).tmp" > $(1); \
	else \
	  touch $(1); \
	fi
endef

define filter_requires = 

  sub get_requires {
    my ($infile) = @_;

    return {}
      if !-s $infile;

    my %requires;

    open my $fh, '<', $infile or
      die "could not open $infile for reading\n";

    while (<$fh>) {
      chomp;
      my ($m,$v) = split ' ', $_;
      $requires{$m} = $v // 0;
    }

    close $fh;

    return \%requires;
  }

  my $skip_requires = get_requires("$ENV{REQUIRES}.skip");
  my $requires_tmp  = get_requires("$ENV{REQUIRES}.xxx");
  my $requires      = get_requires($ENV{REQUIRES});

  my %new_requires;

  # copy preserved modules (ones preceded with '+')
  foreach my $m (keys %{$requires_tmp} ) {
    next if $m !~/^\+/xsm;
    $new_requires{$m} = $requires_tmp->{$m};
  }

  foreach my $m (keys %{$requires} ) {
    # skip modules on skip list
    next if exists $skip_requires->{$m};
    next if exists $requires_tmp->{"+$m"};

    # keep modules from preserved list if versions differ (user must have specified specific version)
    if ( exists $requires_tmp->{$m} && $requires_tmp->{$m} ne $requires->{$m} ) {
      $new_requires{$m} = $requires_tmp->{$m};
    }
    else {
      $new_requires{$m} = $requires->{$m};
   }
  }

  print join q{}, map { "$_ $new_requires{$_}\n" } keys %new_requires;

endef

export s_filter_requires = $(value filter_requires)

requires: $(SOURCE_FILES) ## creates or updates the `requires` file used to populate PREQ_PM section of the Makefile.PL
	$(NO_ECHO)cleanfiles="$@.tmp $@.xxx"; \
	trap 'rm -f $$cleanfiles' EXIT; \
	scan="$(SCAN)"; \
	if [[ "$${scan^^}" = "ON" ]]; then \
	  if test -e "$@"; then \
	    cp "$@" "$@.xxx"; \
	  fi; \
	  $(call scan-deps,$@,lib bin,*.p[ml].in); \
	  if test -e "$@.xxx"; then \
	    requires_list=$$(REQUIRES="$@" perl -e "$$s_filter_requires"); \
	    echo "$$requires_list" | sort > "$@"; \
	  fi; \
	fi

test-requires: $(TESTS) ## creates or update the `test-requires` file used to populate the TEST_REQUIRES section of the Makefile.PL
	$(NO_ECHO)cleanfiles="$@.tmp $@.xxx"; \
	trap 'rm -f $$cleanfiles' EXIT; \
	scan="$(SCAN)"; \
	if [[ "$${scan^^}" = "ON" ]]; then \
	  if test -e "$@"; then \
	    cp "$@" "$@.xxx"; \
	  fi; \
	  $(call scan-deps,$@,t,*.t); \
	  if test -e "$@.xxx"; then \
	    requires_list=$$(REQUIRES="$@" perl -e "$$s_filter_requires"); \
	    echo "$$requires_list" | sort > "$@"; \
	  fi; \
	fi


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
	$(NO_ECHO)buildspec=$$(mktemp); \
	specfile="$(PROJECT_NAME)"; \
	specfile="$${specfile,,}.yml"; \
	if [[ -e "$$specfile" ]]; then \
	  share_files="    - $$specfile\n"; \
	fi; \
	trap 'rm -f $$buildspec' EXIT; \
	sed -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/g' \
	    -e 's/[@]GIT_NAME[@]/$(GIT_NAME)/g' \
	    -e 's/[@]GITHUB_USER[@]/$(GITHUB_USER)/g' \
	    -e 's/[@]GIT_EMAIL[@]/$(GIT_EMAIL)/g' \
	    -e 's/[@]PROJECT_NAME[@]/$(PROJECT_NAME)/g' \
	    -e "s/[@]SHARE_FILES[@]/$$share_files/g" \
	    -e 's/[@]MIN_PERL_VERSION[@]/$(MIN_PERL_VERSION)/g' buildspec.yml.tmpl > $$buildspec; \
	if test -e resources.yml; then \
	  cat resources.yml >> $$buildspec; \
	  rm resources.yml; \
	fi; \
	cp $$buildspec $@;

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
    extra-files \
    provides \
    module.pm.tmpl \
    release-*.{lst,diffs}

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

DOCKER_BUILD_IMAGE ?= debian:trixie
BRANCH             ?= $(shell git branch --show-current)
BUILDER            ?= builder
BUILD_LOG          ?= $(shell echo "build-$$(date +'%Y%m%d%H%M%S').log")
INSTALLER          ?= cpm

.PHONY: build-ci
build-ci:
	@test -n "$(DOCKER)" || (echo "docker unavailable: install docker or set DOCKER" && exit 1); \
	test -x "$$(pwd)/$(BUILDER)" || (echo "no builder. set BUILDER or run make workflow to install builder" && exit 1); \
	repo_url="https://github.com/$(GITHUB_USER)/$(PROJECT_NAME).git"; \
	start_time=$$(date +%s); \
	$(DOCKER) run --rm -v "$$(pwd)/$(BUILDER):/builder:ro" \
	  -e GITHUB_REF_NAME=$(BRANCH) \
	  -e INSTALLER=$(INSTALLER) \
	  $(DOCKER_BUILD_IMAGE) \
	  /bin/bash /builder "$$repo_url" 2>&1 | tee $(BUILD_LOG); \
	end_time=$$(date +%s); \
	total_time=$$(($$end_time - $$start_time)); \
	echo "Build time: $$(date -u -d @$$total_time +%T)" >> $(BUILD_LOG); \
	ln -sf $(BUILD_LOG) build.log; \
	echo "See build.log"

GSOURCE_FILES = $(SOURCE_FILES:.in=)

test: $(GSOURCE_FILES) ## run unit tests
	prove -I lib -v t/

check: $(GSOURCE_FILES) ## syntax check and create source from .in file

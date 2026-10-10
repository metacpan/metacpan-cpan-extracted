#-*- mode: makefile; -*-
# To see available targets"
# make help

# ...before we get too far
ifeq ($(filter grouped-target,$(.FEATURES)),)
$(error GNU Make 4.3 or newer is required)
endif

SHELL := /bin/bash
.SHELLFLAGS := -e -o pipefail -c

# this the user's version from their VERSION file
VERSION := $(shell test -e VERSION || echo 1.0.0 > VERSION; cat VERSION)

PACKAGE_VERSION = $(VERSION)

lc = $(shell v='$(1)'; printf '%s' "$${v,,}")

# this is the current version in your Perl path (but not necessarily the version that produced this Makefile)
BOOTSTRAPPER_VERSION := $(shell perl -MCPAN::Maker::Bootstrapper -e 'print CPAN::Maker::Bootstrapper->VERSION;' 2>/dev/null || true) 

NO_ECHO ?= @
NO_COLOR ?=

BOOTSTRAP_BUILD := $(if $(wildcard build-config.mk),,1)

config.mk:
	$(NO_ECHO)touch $@

build-config.mk: config.mk
	 $(NO_ECHO)cmb create-build-config > $@

include build-config.mk

export MODULE_NAME PACKAGE_VERSION

CMB_UPDATE_CHECK  ?= on
CMB_VERSION_DRIFT ?= fail

DARKPAN_REQUIRES ?=
DARKPAN_URL      ?=
export DARKPAN_URL

LOG_LEVEL ?= info

TARBALL_ORDER_ONLY_PREREQS ?=

GIT_NAME     ?= $(shell $(GIT) config --global user.name 2>/dev/null || echo "Anonymouse")
GIT_EMAIL    ?= $(shell $(GIT) config --global user.email 2>/dev/null || echo "anonymouse@example.org")
GITHUB_USER  ?= $(shell $(GIT) config --global user.github 2>/dev/null || echo "anonymouse")
GIT_USER     := $(GITHUB_USER)
GIT_SHA      := $(shell (test -d .git && $(GIT) rev-parse HEAD 2>/dev/null) || echo 'unknown' )
GIT_DIRTY    := $(shell (test -d .git && $(GIT) describe --always --dirty --abbrev=40 2>/dev/null) || echo 'unknown')

.PHONY: test-dirty
test-dirty:
	$(NO_ECHO)echo $(GIT_DIRTY)

MIN_PERL_VERSION ?= 5.010

MIN_PERL_VERSION_FLAG := $(shell v=$$(test -e buildspec.yml && dnk get .min-perl-version < buildspec.yml 2>/dev/null); [[ -n "$$v" ]] && echo "-m $$v")


cmb_update_check  := $(call lc,$(CMB_UPDATE_CHECK))
cmb_version_drift := $(call lc,$(CMB_VERSION_DRIFT))

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

RENDERED_SOURCE_FILES := $(addsuffix .rendered,$(PERL_MODULES))
.SECONDARY: $(RENDERED_MODULES)

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

ifeq ($(POD),extract)
DEPS += $(POD_MODULES)
endif

MANAGED_MK_FILES = \
    build-init.mk \
    bash-completion.mk \
    bootstrap.mk \
    builder.mk \
    git.mk \
    help.mk \
    local.mk \
    modulino.mk \
    perl.mk \
    publish.mk \
    release-notes.mk \
    test.mk \
    update.mk \
    upgrade.mk \
    version.mk

INCLUDES_DIR = .includes/

INCLUDES_FILES = $(addprefix $(INCLUDES_DIR),$(MANAGED_MK_FILES))
ifeq ($(BOOTSTRAP_BUILD),)
# config.mk should remain first
-include \
    config.mk \
    $(INCLUDES_FILES)
endif

.DEFAULT_GOAL := $(TARBALL)

.PHONY: all
all: $(TARBALL)

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
quick: ## turns off scanning, perltidy, perlcritic, pod checking
	$(NO_ECHO)$(MAKE) SCAN=off LINT=off PODCHECKER=

.PHONY: real-quick
real-quick: ## turns off scanning, perltidy, perlcritic, pod checking, syntax checking
	$(NO_ECHO)$(MAKE) SCAN=off LINT=off PODCHECKER= SYNTAX_CHECKING=off


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


$(TARBALL): $(DEPS) | local/.installed update-available $(TARBALL_ORDER_ONLY_PREREQS) \
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
	  $(CPAN_MAKER) $$SKIP_TESTS -l $(LOG_LEVEL) $$COLOR -b buildspec.yml

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
	$(NO_ECHO)$(BOOTSTRAPPER) dist-file $@ > $@; \
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


ifneq ($(scan_on),)
requires.raw recommends.raw suggests.raw &: $(SOURCE_FILES_IN) ## single scan producing all three library dependency tiers
	$(NO_ECHO)tmpdir="$$(mktemp -d)"; \
	trap 'rm -rf "$$tmpdir" file_list.tmp' EXIT; \
	printf '%s\n' $(SOURCE_FILES_IN) > file_list.tmp; \
	echo "Scanning...lib/, bin/"; \
	PERL5LIB=lib:local/lib/perl5:$$PERL5LIB $(SCANDEPS) -m $(MIN_PERL_VERSION) \
	  --raw \
	  --file-list file_list.tmp \
	  --no-core --filter \
	  --requires-file "$$tmpdir/requires.raw" \
	  --recommends-file "$$tmpdir/recommends.raw" \
	  --suggests-file "$$tmpdir/suggests.raw" >/dev/null; \
	for type in requires recommends suggests; do \
	  if [[ ! -e "$$type.raw" ]] || \
	     ! cmp -s "$$tmpdir/$$type.raw" "$$type.raw"; then \
	    mv "$$tmpdir/$$type.raw" "$$type.raw"; \
	  fi; \
	done

provides: $(addsuffix .in,$(PERL_MODULES))
	$(NO_ECHO)tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	$(BOOTSTRAPPER) provides > "$$tmp"; \
	if [[ ! -e provides ]] || ! cmp -s "$$tmp" provides; then \
	  mv "$$tmp" provides; \
	fi

test-requires.scan: $(TESTS)
	$(NO_ECHO)printf '%s\n' $(TESTS) > file_list.tmp; \
	tmp=$$(mktemp); trap 'rm -f $$tmp' EXIT; \
        echo "Scanning...t/"; \
	PERL5LIB=lib:local/lib/perl5:$$PERL5LIB $(SCANDEPS) $(MIN_PERL_VERSION_FLAG) \
	  --raw \
          --log-level info \
	  --file-list file_list.tmp \
	  --no-core --filter \
	  --requires-file $$tmp > /dev/null; \
	perl -npe 'while(s/  / /g) {}' < $$tmp | sort > $@; \
	rm -f file_list.tmp

test-requires.raw: test-requires.scan
	$(NO_ECHO)sed -e 's/ 0$$/ undef/g' $< > $@

requires: ## creates or updates the `requires` file used to populate PREQ_PM section of the Makefile.PL

recommends: ## creates or updates the `recommends` file (soft, non-eval conditional dependencies)

suggests: ## creates or updates the `suggests` file (eval-wrapped, optional dependencies)

test-requires: ## creates or updates the `test-requires` file used to populate the TEST_REQUIRES section of the Makefile.PL

requires recommends suggests test-requires: %: %.reconciled
	@:

requires.reconciled \
recommends.reconciled \
suggests.reconciled \
test-requires.reconciled &: \
    requires.raw \
    recommends.raw \
    suggests.raw \
    test-requires.raw \
    | provides
	$(NO_ECHO)deps="$$(mktemp)"; \
	output="$$(mktemp)"; \
	trap 'rm -f "$$deps" "$$output"' EXIT; \
	for type in requires recommends suggests; do \
	  if [[ ! -e "$$type.reconciled" || \
	        "$$type.raw" -nt "$$type.reconciled" ]]; then \
	    printf '%s\n' "$$type" >> "$$deps"; \
	  fi; \
	done; \
	if [[ ! -e test-requires.reconciled || \
	      test-requires.raw -nt test-requires.reconciled || \
	      provides -nt test-requires.reconciled ]]; then \
	  printf '%s\n' test-requires >> "$$deps"; \
	fi; \
	if [[ -s "$$deps" ]]; then \
	  $(BOOTSTRAPPER) reconcile-deps $$(cat "$$deps"); \
	fi; \
	if grep -qx 'test-requires' "$$deps"; then \
	  awk 'NR == FNR { provided[$$1] = 1; next } !provided[$$1]' \
	    provides test-requires > "$$output"; \
	  if ! cmp -s "$$output" test-requires; then \
	    mv "$$output" test-requires; \
	  fi; \
	fi; \
	while read -r type; do \
	  touch "$$type.reconciled"; \
	done < "$$deps"
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

GENERATED_FILES += \
    provides \
    test-requires.scan

CLEANFILES += \
    $(BIN_FILES) \
    $(PERL_MODULES) \
    $(POD_MODULES) \
    $(GENERATED_FILES) \
    $(RENDERED_SOURCE_FILES) \
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
    cpanfile.suggests \
    build-config.mk

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
-include extra-files.mk
endif


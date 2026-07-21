#-*- mode: makefile; -*-

PERL       := $(shell command -v perl)
PERLTIDY   := $(shell command -v perltidy)
PERLCRITIC := $(shell command -v perlcritic)
PODCHECKER := $(shell command -v podchecker)

PERL_BIN_FILES = $(patsubst %.pl.in,%.pl,$(filter %.pl.in,$(BIN_FILES:%=%.in)))

PERLINCLUDE ?= -I lib $(addprefix -I ,$(subst :, ,$(PERL5LIB)))

SYNTAX_CHECKING ?= $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_syntax_checking // q{}' 2>/dev/null)

PERLTIDYRC ?= $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_perltidyrc // q{}' 2>/dev/null)

PERLCRITICRC ?= $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_perlcriticrc // q{}' 2>/dev/null)

PERLWC_SKIP ?=

lint_off = $(filter off,$(shell echo $(LINT) | tr '[:upper:]' '[:lower:]'))

# normalize - 'off' or empty disables, anything else enables
syntax_on = $(filter-out off,$(shell echo $(SYNTAX_CHECKING) | tr '[:upper:]' '[:lower:]'))

ifneq ($(PERLTIDY),)
  tidy_on = $(if $(lint_off),,$(filter-out off,$(shell echo $(PERLTIDYRC)      | tr '[:upper:]' '[:lower:]')))
endif

ifneq ($(PERLCRITIC),)
  critic_on  = $(if $(lint_off),,$(filter-out off,$(shell echo $(PERLCRITICRC)    | tr '[:upper:]' '[:lower:]')))
endif

$(eval $(call find-files,TIDY_FILES,lib bin,*.tdy))
$(eval $(call find-files,CRITIC_FILES,lib bin,*.crit))
$(eval $(call find-files,ERR_FILES,lib bin,*.crit))

CLEANFILES += $(TIDY_FILES) $(CRITIC_FILES) $(ERR_FILES)

# ------------------------------------------------------------------
# snippets
# ------------------------------------------------------------------

define run_podextract
	if [[ "$$POD" =~ ^(extract|remove)$$ ]]; then \
	  if [[ -z "$(PODEXTRACT)" ]]; then \
	    echo >&2 "ERROR: Pod::Extract not installed - run cpanm Pod::Extract"; \
	    exit 1; \
	  fi; \
	  nopod_tmp="$$(mktemp)"; \
	  local_cleanfiles="$$local_cleanfiles $$nopod_tmp"; \
	  if [[ "$$POD" = "extract" ]]; then \
	    podout="$@"; podout="$${podout%.pm}.pod"; \
	  else \
	    podout="/dev/null"; \
	  fi; \
	  $(PODEXTRACT) -i "$$module_tmp" -o "$$nopod_tmp" -p "$$podout"; \
	  cp "$$nopod_tmp" "$$module_tmp"; \
	fi
endef

define check_syntax_pm
	local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles' EXIT; \
	skip=0; \
	perlwc_skip=$$(mktemp); local_cleanfiles="$$local_cleanfiles $$perlwc_skip"; \
	if [[ -e compile.skip ]]; then \
	  cp compile.skip $$perlwc_skip; \
	fi; \
	printf "%s\n" $(PERLWC_SKIP) >> $$perlwc_skip; \
	for f in $$(cat $$perlwc_skip); do \
	  [[ "$$f" = "$<" ]] && skip=1 && break; \
	done; \
	if [[ "$$skip" -eq 0 ]]; then \
	  module=$$(echo $< | perl -npe 's{^lib/}{}; s/\//::/g; s/\.pm$$//;'); \
	  errfile=$$(mktemp); \
	  local_cleanfiles="$$local_cleanfiles $$errfile"; \
	  perl -wc $(PERLINCLUDE) -M"$$module" -e 1 2>$$errfile \
	    || { rm -f "$<"; cat $$errfile; exit 1; }; \
	  podcheck="$$($(PODCHECKER) $< 2>&1 || true)"; \
	  echo "$$podcheck" | grep -q "does not contain\|OK" || { rm -f "$<"; echo "$$podcheck"; exit 1; } \
	fi
endef

define check_syntax_pl
	local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles' EXIT; \
	skip=0; \
	perlwc_skip=$$(mktemp); local_cleanfiles="$$local_cleanfiles $$perlwc_skip"; \
	if [[ -e compile.skip ]]; then \
	  cp compile.skip $$perlwc_skip; \
	fi; \
	printf "%s\n" $(PERLWC_SKIP) >> $$perlwc_skip; \
	for f in $$(cat $$perlwc_skip); do \
	  [[ "$$f" = "$<" ]] && skip=1 && break; \
	done; \
	if [[ "$$skip" -eq 0 ]]; then \
	  errfile=$$(mktemp); \
	  local_cleanfiles="$$local_cleanfiles $$errfile"; \
	  perl -wc $(PERLINCLUDE) -e 1 2>$$errfile \
	    || { rm -f "$<"; cat $$errfile; exit 1; }; \
	  podcheck="$$($(PODCHECKER) $< 2>&1 || true)"; \
	  echo "$$podcheck" | grep -q "does not contain\|OK" || { rm -f "$<"; echo "$$podcheck"; exit 1; } \
	fi
endef

# ------------------------------------------------------------------
# sentinel rules - real gate or no-op touch based on configuration
# ------------------------------------------------------------------

# sentinel rules now depend on %.pm not %.pm.in

%.pm.tdy: %.pm
ifneq ($(tidy_on),)
	$(NO_ECHO)test -e "$(PERLTIDYRC)" \
	  || { echo "ERROR: $(PERLTIDYRC) not found"; exit 1; }; \
	if [[ -z "$(PERLTIDY)" ]]; then \
	  echo "ERROR: perltidy not found - install with: cpanm Perl::Tidy"; \
	  exit 1; \
	fi; \
	echo >&2 "Checking tidiness...$<"; \
	$(PERLTIDY) --profile="$(PERLTIDYRC)" $< >/dev/null 2>&1; \
	diff -q "$<" "$<.tdy" >/dev/null 2>&1 \
	  || { echo "ERROR: $< is not tidy - run: make tidy"; rm -f "$<.tdy" "$@"; exit 1; }; \
	rm -f "$<.tdy"; \
	touch "$@"
else
	$(NO_ECHO)touch "$@"
endif

# note that perlcritic output errors on STDOUT
%.pm.crit: %.pm
ifneq ($(critic_on),)
	$(NO_ECHO)test -e "$(PERLCRITICRC)" \
	  || { echo "ERROR: $(PERLCRITICRC) not found"; exit 1; }; \
	if [[ -z "$(PERLCRITIC)" ]]; then \
	  echo "ERROR: perlcritic not found - install with: cpanm Perl::Critic"; \
	  exit 1; \
	fi; \
	echo >&2 "Critiquing...$<"; \
	$(PERLCRITIC) --profile="$(PERLCRITICRC)" $< 1>&2 \
	  || { echo "ERROR: $< fails perlcritic"; rm -f "$@"; exit 1; }; \
	touch "$@"
else
	$(NO_ECHO)touch "$@"
endif

%.pl.tdy: %.pl
ifneq ($(tidy_on),)
	$(NO_ECHO)test -e "$(PERLTIDYRC)" \
	  || { echo "ERROR: $(PERLTIDYRC) not found"; exit 1; }; \
	if [[ -z "$(PERLTIDY)" ]]; then \
	  echo "ERROR: perltidy not found - install with: cpanm Perl::Tidy"; \
	  exit 1; \
	fi; \
	echo >&2 "Checking tidiness...$<"; \
	$(PERLTIDY) --profile="$(PERLTIDYRC)" $<; \
	diff -q "$<" "$<.tdy" 2>/dev/null \
	  || { echo "ERROR: $< is not tidy - run: make tidy"; rm -f "$<.tdy" "$@"; exit 1; }; \
	rm -f "$<.tdy"; \
	touch "$@"
else
	$(NO_ECHO)touch "$@"
endif

%.pl.crit: %.pl
ifneq ($(critic_on),)
	$(NO_ECHO)test -e "$(PERLCRITICRC)" \
	  || { echo "ERROR: $(PERLCRITICRC) not found"; exit 1; }; \
	if [[ -z "$(PERLCRITIC)" ]]; then \
	  echo "ERROR: perlcritic not found - install with: cpanm Perl::Critic"; \
	  exit 1; \
	fi; \
	$(PERLCRITIC) --profile="$(PERLCRITICRC)" $< \
	  || { echo "ERROR: $< fails perlcritic"; rm -f "$@"; exit 1; }; \
	touch "$@"
else
	$(NO_ECHO)touch "$@"
endif

# ------------------------------------------------------------------
# pattern rules - always depend on sentinels
# ------------------------------------------------------------------

# %.pm/%.pl are now reached via a pattern-rule chain (%.pm.checked ->
# %.pm -> %.pm.in). Without this, GNU Make treats them as disposable
# intermediate files and deletes them right after check-syntax uses
# them, even though they're the actual build deliverables.
.PRECIOUS: %.pm %.pl

%.pm: %.pm.in
	$(NO_ECHO)module_tmp="$$(mktemp)"; \
	local_cleanfiles="$$module_tmp"; \
	trap 'rm -f $$local_cleanfiles' EXIT; \
	sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' \
	    -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' $< > "$$module_tmp"; \
	$(run_podextract); \
	rm -f "$@"; \
	cp "$$module_tmp" "$@"; \
	chmod -w "$@"

%.pl: %.pl.in
	$(NO_ECHO)rm -f "$@"; \
	sed -e 's/[@]PACKAGE_VERSION[@]/$(VERSION)/' \
	    -e 's/[@]MODULE_NAME[@]/$(MODULE_NAME)/' $< > "$@"; \
	chmod +x "$@"; \
	chmod -w "$@"

# ------------------------------------------------------------------
# syntax-check sentinels - deliberately a SEPARATE pass from the
# templating rules above. deps.mk's own remake (deps.mk: $(PERL_MODULES))
# only needs templating to succeed, and templating can never fail for
# cross-module ordering reasons (no `use`d sibling resolution happens
# there). That guarantees deps.mk can always regenerate and GNU Make's
# automatic restart-after-remake always completes -- even when a
# freshly-added `use` references a sibling module that hasn't been
# built yet. Syntax checking (which DOES need siblings to exist) only
# runs here, after every .pm/.pl in this build is already on disk, so
# ordering is a non-issue by the time it runs.
# ------------------------------------------------------------------

%.pm.checked: %.pm
	$(NO_ECHO)$(if $(syntax_on),$(check_syntax_pm))
	@touch $@

%.pl.checked: %.pl
	$(NO_ECHO)$(if $(syntax_on),$(check_syntax_pl))
	@touch $@

.PHONY: check-syntax
check-syntax: $(PERL_MODULES:%.pm=%.pm.checked) $(PERL_BIN_FILES:%.pl=%.pl.checked) ## verify all built modules/scripts compile and pass podchecker

CLEANFILES += $(PERL_MODULES:%.pm=%.pm.checked) $(PERL_BIN_FILES:%.pl=%.pl.checked)

# ------------------------------------------------------------------
# convenience targets
# ------------------------------------------------------------------

.PHONY: tidy critic lint

tidy: ## run perltidy on all source files
	$(NO_ECHO)if [[ -z "$(PERLTIDYRC)" ]]; then \
	  echo "ERROR: PERLTIDYRC not set - add perltidyrc to your config or set PERLTIDYRC=path"; \
	  exit 1; \
	fi; \
	test -e "$(PERLTIDYRC)" \
	  || { echo "ERROR: $(PERLTIDYRC) not found"; exit 1; }; \
	if [[ -z "$(PERLTIDY)" ]]; then \
	  echo "ERROR: perltidy not found - install with: cpanm Perl::Tidy"; \
	  exit 1; \
	fi; \
	$(MAKE) check-syntax SYNTAX_CHECKING=on PERLTIDYRC="" PERLCRITICRC=""; \
        FILE_LIST=$$(find lib bin -name '*.p[lm].in'); \
	for f in $$FILE_LIST; do \
	  echo "tidying: $$f"; \
	  $(PERLTIDY) --profile="$(PERLTIDYRC)" "$$f"; \
	  mv "$$f.tdy" "$$f"; \
	done

critic: ## run perlcritic on all source files
	$(NO_ECHO)if [[ -z "$(PERLCRITICRC)" ]]; then \
	  echo "ERROR: PERLCRITICRC not set - add perlcriticrc to your config or set PERLCRITICRC=path"; \
	  exit 1; \
	fi; \
	test -e "$(PERLCRITICRC)" \
	  || { echo "ERROR: $(PERLCRITICRC) not found"; exit 1; }; \
	if [[ -z "$(PERLCRITIC)" ]]; then \
	  echo "ERROR: perlcritic not found - install with: cpanm Perl::Critic"; \
	  exit 1; \
	fi; \
	$(MAKE) SYNTAX_CHECKING=on PERLTIDYRC="" PERLCRITICRC=""; \
        PERL_SCRIPTS=$$(find bin/ -name '*.pl'); \
	$(PERLCRITIC) --profile="$(PERLCRITICRC)" $(PERL_MODULES); \
	test -n "$$PERL_SCRIPTS" && $(PERLCRITIC) --profile="$(PERLCRITICRC)" $$PERL_SCRIPTS

lint: ## run all linting tools (tidy + critic)
	$(NO_ECHO)$(MAKE) tidy critic

# dependencies
#
# deps.mk has a self-remake rule (see Makefile: `deps.mk: $(PERL_MODULES)`)
# that requires the built .pm files to exist. GNU Make always checks
# whether included makefiles are up to date *before* running the
# requested goal -- including `clean` -- so an unguarded include here
# causes `make clean` to build every .pm file and then immediately
# delete them. Skip the include for clean/distclean goals so make
# doesn't build anything it's only about to remove.
ifeq ($(filter clean distclean,$(MAKECMDGOALS)),)
-include deps.mk
endif

# custom make rules
#
# project.mk is plain data (module dependency edges) with no rule to
# remake itself, so including it doesn't trigger the same forced-build
# problem as deps.mk. It's also the conventional place to drop extra
# clean-local:: recipes, so it must stay included unconditionally --
# guarding it the way deps.mk is guarded above would silently skip
# those clean-local:: hooks whenever `make clean` runs.
-include project.mk


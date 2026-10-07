#-*- mode: makefile; -*-

PERL       := $(shell command -v perl)
PERLTIDY   := $(shell command -v perltidy)
PERLCRITIC := $(shell command -v perlcritic)

PODCHECKER := $(shell command -v podchecker)
CPM        := $(shell command -v cpm)
CARTON     := $(shell command -v carton)

PERL_BIN_FILES = $(patsubst %.pl.in,%.pl,$(filter %.pl.in,$(BIN_FILES:%=%.in)))

PERLINCLUDE ?= -I lib -I local/lib/perl5

ifeq ($(origin SYNTAX_CHECKING),undefined)
  SYNTAX_CHECKING := $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_syntax_checking // q{}' 2>/dev/null)
endif

ifeq ($(origin PERLTIDYRC),undefined)
  PERLTIDYRC := $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_perltidyrc // q{}' 2>/dev/null)
endif

ifeq ($(origin PERLCRITICRC),undefined)
  PERLCRITICRC := $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_perlcriticrc // q{}' 2>/dev/null)
endif

lint_off  := $(filter off,$(call lc,$(LINT)))
syntax_on := $(filter-out off,$(call lc,$(SYNTAX_CHECKING)))
tidy_on   := $(if $(lint_off),,$(PERLTIDY))
critic_on := $(if $(lint_off),,$(PERLCRITIC))

PERLWC_SKIP ?=

PERLCRITIC_SEVERITY ?= 5
PERLCRITIC_THEME ?= pbp

$(eval $(call find-files,TIDY_FILES,lib bin,*.tdy))
$(eval $(call find-files,CRITIC_FILES,lib bin,*.crit))
$(eval $(call find-files,ERR_FILES,lib bin,*.crit))

PERL_CHECKED_FILES     = $(PERL_MODULES:%=%.checked)
PERL_BIN_CHECKED_FILES = $(PERL_BIN_FILES:%=%.checked)

CLEANFILES += $(TIDY_FILES) $(CRITIC_FILES) $(ERR_FILES) $(PERL_CHECKED_FILES) $(PERL_BIN_CHECKED_FILES)

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
	  echo -n "Checking SYNTAX...$<..."; \
	  PERL5LIB= perl -wc $(PERLINCLUDE) -M"$$module" -e 1 2>$$errfile \
	    || { rm -f "$<"; cat $$errfile; exit 1; }; \
	  echo "OK"; \
	  echo -n "Checking POD...$<..."; \
	  podcheck="$$($(PODCHECKER) $< 2>&1 || true)"; \
	  echo "$$podcheck" | grep -q "does not contain\|OK" || { rm -f "$<"; echo "$$podcheck"; exit 1; }; \
	  echo "OK"; \
	fi
endef

define check_syntax_pl
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
	  echo "Checking...$<"; \
	  PERL5LIB= perl -wc $(PERLINCLUDE) "$<" 2>$$errfile \
	    || { rm -f "$<"; cat $$errfile; exit 1; }; \
	  echo "$< OK"; \
	  echo "Checking POD...$<"; \
	  podcheck="$$($(PODCHECKER) $< 2>&1 || true)"; \
	  echo "$$podcheck" | grep -q "does not contain\|OK" || { rm -f "$<"; echo "$$podcheck"; exit 1; }; \
	  echo "$< OK"; \
	fi
endef

%.pm.checked: %.pm | local/.installed
	$(NO_ECHO)local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles' EXIT; \
	$(check_syntax_pm); \
	touch "$@"

%.pl.checked: %.pl | local/.installed
	$(NO_ECHO)local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles' EXIT; \
	$(check_syntax_pl); \
	touch "$@"

# ------------------------------------------------------------------
# sentinel rules - real gate or no-op touch based on configuration
# ------------------------------------------------------------------

# sentinel rules now depend on %.pm not %.pm.in

%.pm.tdy: %.pm
ifneq ($(tidy_on),)
	$(NO_ECHO)if [[ -n "$(PERLTIDYRC)" && ! -e "$(PERLTIDYRC)" ]]; then \
	  echo "ERROR: $(PERLTIDYRC) not found"; \
	  exit 1; \
	fi; \
	if [[ -z "$(PERLTIDY)" ]]; then \
	  echo "ERROR: perltidy not found - install with: cpanm Perl::Tidy"; \
	  exit 1; \
	fi; \
	echo -n "Checking TIDINESS...$<..."; \
	$(PERLTIDY) $(if $(PERLTIDYRC),--profile="$(PERLTIDYRC)") $< >/dev/null 2>&1; \
	diff -q "$<" "$<.tdy" >/dev/null 2>&1 \
	  || { echo "ERROR: $< is not tidy - run: make tidy"; rm -f "$<.tdy" "$@"; exit 1; }; \
	rm -f "$<.tdy"; \
	echo "OK"; \
	touch "$@"
else
	$(NO_ECHO)touch "$@"
endif

# note that perlcritic output errors on STDOUT
%.pm.crit: %.pm
ifneq ($(critic_on),)
	$(NO_ECHO)if [[ -n "$(PERLCRITICRC)"  && ! -e "$(PERLCRITICRC)" ]]; then \
	  echo "ERROR: $(PERLCRITICRC) not found"; \
	exit 1; \
	fi; \
	if [[ -z "$(PERLCRITIC)" ]]; then \
	  echo "ERROR: perlcritic not found - install with: cpanm Perl::Critic"; \
	  exit 1; \
	fi; \
	echo -n "Checking PERLCRITIC...$<..."; \
	$(PERLCRITIC) \
	  --theme=$(PERLCRITIC_THEME) $(if $(PERLCRITICRC),--profile="$(PERLCRITICRC)") \
	  --severity=$(PERLCRITIC_SEVERITY) $<  >/dev/null 2>&1 | tee $@ || { echo "ERROR: $< fails perlcritic"; exit 1; }; \
	echo "OK"
else
	$(NO_ECHO)touch "$@"
endif

%.pl.tdy: %.pl
ifneq ($(tidy_on),)
	$(NO_ECHO)if [[ -n "$(PERLTIDYRC)"  && ! -e "$(PERLTIDYRC)" ]]; then \
	  echo "ERROR: $(PERLTIDYRC) not found"; \
	exit 1; \
	fi; \
	if [[ -z "$(PERLTIDY)" ]]; then \
	  echo "ERROR: perltidy not found - install with: cpanm Perl::Tidy"; \
	  exit 1; \
	fi; \
	echo >&2 "Checking tidiness...$<"; \
	$(PERLTIDY) $(if $(PERLTIDYRC),--profile="$(PERLTIDYRC)") $<; \
	diff -q "$<" "$<.tdy" 2>/dev/null \
	  || { echo "ERROR: $< is not tidy - run: make tidy"; rm -f "$<.tdy" "$@"; exit 1; }; \
	rm -f "$<.tdy"; \
	touch "$@"
else
	$(NO_ECHO)touch "$@"
endif

%.pl.crit: %.pl
ifneq ($(critic_on),)
	$(NO_ECHO)if [[ -n "$(PERLCRITICRC)" && ! -e "$(PERLCRITICRC)" ]]; \
	  echo "ERROR: $(PERLCRITICRC) not found"; \
	  exit 1; \
	fi; 
	if [[ -z "$(PERLCRITIC)" ]]; then \
	  echo "ERROR: perlcritic not found - install with: cpanm Perl::Critic"; \
	  exit 1; \
	fi; \
	echo >&2 "Critiquing...$<"; \
	$(PERLCRITIC) \
	  --theme=$(PERLCRITIC_THEME) \
	  --severity=$(PERLCRITIC_SEVERITY) \
	  $(if $(PERLCRITICRC),--profile="$(PERLCRITICRC)") $< 2>&1 | tee $@ || { echo "ERROR: $< fails perlcritic"; exit 1; };
else
	$(NO_ECHO)touch "$@"
endif

# $(call gen-vars-file,PATH): write NAME=value pairs to PATH, values
# resolved by make and written verbatim (no shell, so quotes/&/spaces in
# values survive). Caller consumes PATH, then removes it.
gen-vars-file = $(file >$(1),)$(foreach v,$(TEMPLATE_VARS),$(file >>$(1),$(v)=$($(v))))

# ------------------------------------------------------------------
# pattern rules
# ------------------------------------------------------------------
#

# Module/script generation is separate from syntax validation.
# The .checked sentinels record that the current generated artifact
# has passed syntax/POD checks.

%.pm: %.pm.in
	$(call gen-vars-file,$<.vars)
	$(NO_ECHO)module_tmp="$$(mktemp)"; \
	local_cleanfiles="$$module_tmp"; \
	trap 'rm -f $$local_cleanfiles $<.vars' EXIT; \
	$(BOOTSTRAPPER) resolve-vars $< > "$$module_tmp"; \
	$(run_podextract); \
	rm -f "$@"; \
	cp "$$module_tmp" "$@"; \
	chmod -w "$@"

%.pl: %.pl.in
	$(call gen-vars-file,$<.vars)
	$(NO_ECHO)local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles $<.vars' EXIT; \
	rm -f "$@"; \
	$(BOOTSTRAPPER) resolve-vars $< > $@; \
	chmod +x "$@"; \
	chmod -w "$@"

.PHONY: check-syntax
ifneq ($(syntax_on),)
check-syntax: $(PERL_CHECKED_FILES) $(PERL_BIN_CHECKED_FILES)
else
check-syntax:
endif

# ------------------------------------------------------------------
# convenience targets
# ------------------------------------------------------------------

.PHONY: tidy critic lint

tidy: ## run perltidy on all source files
	$(NO_ECHO)if [[ -z "$(PERLTIDY)" ]]; then \
	  echo "ERROR: perltidy not found - install with: cpanm Perl::Tidy"; \
	  exit 1; \
	fi; \
	if [[ -n "$(PERLTIDYRC)" && ! -e "$(PERLTIDYRC)" ]]; then \
	  echo "ERROR: $(PERLTIDYRC) not found"; \
	  exit 1; \
	fi; \
	if [[ -z "$(PERLTIDYRC)" ]]; then \
	  echo "WARNING: PERLTIDYRC not set - using perltidy defaults"; \
	fi; \
	$(MAKE) check-syntax SYNTAX_CHECKING=on LINT=off; \
	FILE_LIST=$$(find lib bin -name '*.p[lm].in'); \
	for f in $$FILE_LIST; do \
	  echo "tidying: $$f"; \
	  $(PERLTIDY) $(if $(PERLTIDYRC),--profile="$(PERLTIDYRC)") "$$f"; \
	  mv "$$f.tdy" "$$f"; \
	done

critic: ## run perlcritic on all source files
	$(NO_ECHO)if [[ -z "$(PERLCRITIC)" ]]; then \
	  echo "ERROR: perlcritic not found - install with: cpanm Perl::Critic"; \
	  exit 1; \
	fi; \
	if [[ -n "$(PERLCRITICRC)" && ! -e "$(PERLCRITICRC)" ]]; then \
	  echo "ERROR: $(PERLCRITICRC) not found"; \
	  exit 1; \
	fi; \
	if [[ -z "$(PERLCRITICRC)" ]]; then \
	  echo "WARNING: PERLCRITICRC not set - using perlcritic defaults"; \
	fi; \
	$(MAKE) check-syntax SYNTAX_CHECKING=on LINT=off; \
	PERL_SCRIPTS=$$(find bin/ -name '*.pl'); \
	$(PERLCRITIC) \
	  $(if $(PERLCRITICRC),--profile="$(PERLCRITICRC)") \
	  --theme=$(PERLCRITIC_THEME) \
	  --severity=$(PERLCRITIC_SEVERITY) \
	  $(PERL_MODULES); \
	if [[ -n "$$PERL_SCRIPTS" ]]; then \
	  $(PERLCRITIC) \
	    $(if $(PERLCRITICRC),--profile="$(PERLCRITICRC)") \
	    --theme=$(PERLCRITIC_THEME) \
	    --severity=$(PERLCRITIC_SEVERITY) \
	    $$PERL_SCRIPTS; \
	fi

lint: ## run all linting tools (tidy + critic)
	$(NO_ECHO)$(MAKE) tidy critic

ifneq ($(syntax_on),)

include deps.mk

# deps.mk depends on SOURCE (.pm.in), not the built .pm targets.
# cmb create-deps already scans .pm.in directly, so this makes deps.mk
# regenerate purely from source edits -- no build artifacts involved,
# so there's no chicken-and-egg with $(PERL_MODULES) needing to be
# built before deps.mk can be regenerated, and 'make clean' can never
# trigger a rebuild through this include (clean doesn't touch .pm.in).
deps.mk: $(SOURCE_FILES_IN)
	$(NO_ECHO)cmb create-deps > $@.tmp \
	  && mv $@.tmp $@ \
	  || { rm -f $@.tmp; false; }

endif

# custom make rules
#
# project.mk is plain data (module dependency edges) with no rule to
# remake itself. It's also the conventional place to drop extra
# clean-local:: recipes, so it must stay included unconditionally in
# all cases
-include project.mk


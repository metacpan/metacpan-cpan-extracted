#-*- mode: makefile; -*-

PERL       := $(shell command -v perl)
PERLTIDY   := $(shell command -v perltidy)
PERLCRITIC := $(shell command -v perlcritic)
PODCHECKER := $(shell command -v podchecker)
CPM        := $(shell command -v cpm)
CARTON     := $(shell command -v carton)

PERL_BIN_FILES = $(patsubst %.pl.in,%.pl,$(filter %.pl.in,$(BIN_FILES:%=%.in)))

PERLINCLUDE ?= -I lib -I local/lib/perl5

SYNTAX_CHECKING ?= $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_syntax_checking // q{}' 2>/dev/null)

PERLTIDYRC ?= $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_perltidyrc // q{}' 2>/dev/null)

PERLCRITICRC ?= $(shell $(PERL) -MCPAN::Maker::ConfigReader \
    -e 'print CPAN::Maker::ConfigReader->new->cpan_maker_perlcriticrc // q{}' 2>/dev/null)

PERLWC_SKIP ?=

PERLCRITIC_SEVERITY ?= 5
PERLCRITIC_THEME ?= pbp

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
	skip=0; \
	perlwc_skip=$$(mktemp); local_cleanfiles="$$local_cleanfiles $$perlwc_skip"; \
	if [[ -e compile.skip ]]; then \
	  cp compile.skip $$perlwc_skip; \
	fi; \
	printf "%s\n" $(PERLWC_SKIP) >> $$perlwc_skip; \
	for f in $$(cat $$perlwc_skip); do \
	  [[ "$$f" = "$@" ]] && skip=1 && break; \
	done; \
	if [[ "$$skip" -eq 0 ]]; then \
	  module=$$(echo $@ | perl -npe 's{^lib/}{}; s/\//::/g; s/\.pm$$//;'); \
	  errfile=$$(mktemp); \
	  local_cleanfiles="$$local_cleanfiles $$errfile"; \
	  PERL5LIB= perl -wc $(PERLINCLUDE) -M"$$module" -e 1 2>$$errfile \
	    || { rm -f "$@"; cat $$errfile; exit 1; }; \
	  podcheck="$$($(PODCHECKER) $@ 2>&1 || true)"; \
	  echo "$$podcheck" | grep -q "does not contain\|OK" || { rm -f "$@"; echo "$$podcheck"; exit 1; } \
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
	  [[ "$$f" = "$@" ]] && skip=1 && break; \
	done; \
	if [[ "$$skip" -eq 0 ]]; then \
	  errfile=$$(mktemp); \
	  local_cleanfiles="$$local_cleanfiles $$errfile"; \
	  PERL5LIB= perl -wc $(PERLINCLUDE) -e 1 2>$$errfile \
	    || { rm -f "$@"; cat $$errfile; exit 1; }; \
	  podcheck="$$($(PODCHECKER) $@ 2>&1 || true)"; \
	  echo "$$podcheck" | grep -q "does not contain\|OK" || { rm -f "$@"; echo "$$podcheck"; exit 1; } \
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
	set -eo pipefail; \
	$(PERLCRITIC) \
	  --theme=$(PERLCRITIC_THEME) \
	  --severity=$(PERLCRITIC_SEVERITY) \
	  --profile="$(PERLCRITICRC)" $<  2>&1 | tee $@ || { echo "ERROR: $< fails perlcritic"; exit 1; };
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
	echo >&2 "Critiquing...$<"; \
	set -eo pipefail; \
	$(PERLCRITIC) \
	  --theme=$(PERLCRITIC_THEME) \
	  --severity=$(PERLCRITIC_SEVERITY) \
	  --profile="$(PERLCRITICRC)" $<  2>&1 | tee $@ || { echo "ERROR: $< fails perlcritic"; exit 1; };
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
# Templating and syntax-checking are combined again (previously split
# into %.pm.checked/%.pl.checked sentinels + a check-syntax target to
# work around a deps.mk chicken-and-egg problem). That problem is now
# solved at the source: deps.mk depends on the .pm.in/.pl.in SOURCE
# files, not the built .pm/.pl targets (see Makefile:
# `deps.mk: $(PERL_MODULES:%=%.in)`), so deps.mk can always regenerate
# -- and its edges are always current -- before anything gets built.
# Real graph edges are respected by GNU Make even under -j, so the
# combined rule below builds/checks modules in correct dependency
# order without needing a separate phase-barrier pass.

%.pm: %.pm.in | local
	$(call gen-vars-file,$<.vars)
	$(NO_ECHO)module_tmp="$$(mktemp)"; \
	local_cleanfiles="$$module_tmp"; \
	trap 'rm -f $$local_cleanfiles $<.vars' EXIT; \
	$(BOOTSTRAPPER) resolve-vars $< > "$$module_tmp"; \
	$(run_podextract); \
	rm -f "$@"; \
	cp "$$module_tmp" "$@"; \
	chmod -w "$@"; \
	$(if $(syntax_on),$(check_syntax_pm))

%.pl: %.pl.in | local
	$(call gen-vars-file,$<.vars)
	$(NO_ECHO)local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles $<.vars' EXIT; \
	rm -f "$@"; \
	$(BOOTSTRAPPER) resolve-vars $< > $@; \
	chmod +x "$@"; \
	chmod -w "$@"; \
	$(if $(syntax_on),$(check_syntax_pl))

# kept as a convenience alias (Makefile's $(TARBALL) target depends on
# this explicitly) -- syntax checking is bundled into the rules above
# again, so this is just $(PERL_MODULES)/$(PERL_BIN_FILES) by another
# name.
.PHONY: check-syntax
check-syntax: $(PERL_MODULES) $(PERL_BIN_FILES) ## verify all built modules/scripts compile and pass podchecker

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
	$(MAKE) check-syntax SYNTAX_CHECKING=on PERLTIDYRC="" PERLCRITICRC=""; \
        PERL_SCRIPTS=$$(find bin/ -name '*.pl'); \
	$(PERLCRITIC) --profile="$(PERLCRITICRC)" \
	  --theme=$(PERLCRITIC_THEME) \
	  --severity=$(PERLCRITIC_SEVERITY) \
	  --profile="$(PERLCRITICRC)" $(PERL_MODULES); \
	if [[ -n "$$PERL_SCRIPTS" ]]; then \
	  $(PERLCRITIC) 
	    --profile="$(PERLCRITICRC)" $$PERL_SCRIPTS; \
	    --theme=$(PERLCRITIC_THEME) \
	    --severity=$(PERLCRITIC_SEVERITY) \
	    --profile="$(PERLCRITICRC)" $$PERL_SCRIPTS; \
	fi

lint: ## run all linting tools (tidy + critic)
	$(NO_ECHO)$(MAKE) tidy critic

# dependencies
#
# deps.mk's self-remake rule now depends on the .pm.in/.pl.in SOURCE
# files (see Makefile: `deps.mk: $(PERL_MODULES:%=%.in)`), not the
# built .pm/.pl targets. `make clean` never touches source files, so
# including this unconditionally can no longer force a build-then-
# delete cycle during clean/distclean the way it used to when deps.mk
# depended on $(PERL_MODULES) directly.
-include deps.mk

# custom make rules
#
# project.mk is plain data (module dependency edges) with no rule to
# remake itself. It's also the conventional place to drop extra
# clean-local:: recipes, so it must stay included unconditionally in
# all cases, same as deps.mk above.
-include project.mk


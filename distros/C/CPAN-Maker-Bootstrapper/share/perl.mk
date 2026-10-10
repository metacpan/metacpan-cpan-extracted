#-*- mode: makefile; -*-

PERL_BIN_FILES = $(patsubst %.pl.in,%.pl,$(filter %.pl.in,$(BIN_FILES:%=%.in)))

PERLINCLUDE ?= -I lib -I local/lib/perl5

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

ifeq ($(POD),extract)

%.pm %.pod &: %.pm.rendered
	$(NO_ECHO)$(PODEXTRACT) -i $< -o $*.pm -p $*.pod

else ifeq ($(POD),remove)

%.pm: %.pm.rendered
	$(NO_ECHO)$(PODEXTRACT) -i $< -o $@ -p /dev/null

else

%.pm: %.pm.rendered
	$(NO_ECHO)cp $< $@

endif

# ------------------------------------------------------------------
# snippets
# ------------------------------------------------------------------
define check_pod
	if [[ -n "$(PODCHECKER)" ]]; then \
	  echo -n "Checking POD...$(1)..."; \
	  podcheck="$$($(PODCHECKER) $(1) 2>&1 || true)"; \
	  echo "$$podcheck" | grep -q "does not contain\|OK" \
	    || { echo "$$podcheck"; exit 1; }; \
	  echo "OK"; \
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
	fi
endef

%.pm.checked: %.pm %.pm.rendered | local/.installed
	$(NO_ECHO)local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles' EXIT; \
	$(check_syntax_pm); \
	$(call check_pod,$(word 2,$^)); \
	touch "$@"

%.pl.checked: %.pl | local/.installed
	$(NO_ECHO)local_cleanfiles=""; \
	trap 'rm -f $$local_cleanfiles' EXIT; \
	$(check_syntax_pl); \
	$(call check_pod,$<); \
	touch "$@"

$(addsuffix .tdy,$(PERL_MODULES) $(PERL_BIN_FILES)) &: $(PERL_MODULES) $(PERL_BIN_FILES)
ifneq ($(tidy_on),)
	$(NO_ECHO)tidy_files="$$(mktemp)"; \
	trap 'rm -f "$$tidy_files"' EXIT; \
	for file in $(PERL_MODULES) $(PERL_BIN_FILES); do \
	  if [[ ! -e "$$file.tdy" || "$$file" -nt "$$file.tdy" ]]; then \
	    printf '%s\n' "$$file" >> "$$tidy_files"; \
	  fi; \
	done; \
	if [[ -s "$$tidy_files" ]]; then \
	  echo -n "Checking PERLTIDY..."; \
	  $(BOOTSTRAPPER) perltidy --file-list "$$tidy_files" \
	    $(if $(PERLTIDYRC),--profile="$(PERLTIDYRC)"); \
	  echo "OK"; \
	fi
else
	$(NO_ECHO)touch $(addsuffix .tdy,$(PERL_MODULES) $(PERL_BIN_FILES))
endif

$(addsuffix .crit,$(PERL_MODULES) $(PERL_BIN_FILES)) &: $(PERL_MODULES) $(PERL_BIN_FILES)
ifneq ($(critic_on),)
	$(NO_ECHO)critic_files="$$(mktemp)"; \
	trap 'rm -f "$$critic_files"' EXIT; \
	for file in $(PERL_MODULES) $(PERL_BIN_FILES); do \
	  if [[ ! -e "$$file.crit" || "$$file" -nt "$$file.crit" ]]; then \
	    printf '%s\n' "$$file" >> "$$critic_files"; \
	  fi; \
	done; \
	if [[ -s "$$critic_files" ]]; then \
	  echo -n "Checking PERLCRITIC..."; \
	  $(BOOTSTRAPPER) perlcritic \
	    --file-list "$$critic_files" \
	    --theme=$(PERLCRITIC_THEME) \
	    --severity=$(PERLCRITIC_SEVERITY) \
	    $(if $(PERLCRITICRC),--profile="$(PERLCRITICRC)"); \
	  echo "OK"; \
	fi
else
	$(NO_ECHO)touch $(addsuffix .crit,$(PERL_MODULES) $(PERL_BIN_FILES))
endif

# $(call gen-vars-file,PATH): write NAME=value pairs to PATH, values
# resolved by make and written verbatim (no shell, so quotes/&/spaces in
# values survive). Caller consumes PATH, then removes it.
gen-vars-file = $(file >$(1),)$(foreach v,$(TEMPLATE_VARS),$(file >>$(1),$(v)=$($(v))))

# ------------------------------------------------------------------
# pattern rules
# ------------------------------------------------------------------
#


$(addsuffix .rendered,$(PERL_MODULES)) &: $(addsuffix .in,$(PERL_MODULES))
	$(call gen-vars-file,resolve-vars.vars)
	$(NO_ECHO)render_files="$$(mktemp)"; \
	trap 'rm -f "$$render_files" resolve-vars.vars' EXIT; \
	for source in $(addsuffix .in,$(PERL_MODULES)); do \
	    rendered="$${source%.in}.rendered"; \
	    if [[ ! -e "$$rendered" || "$$source" -nt "$$rendered" ]]; then \
	        printf '%s\n' "$$source" >> "$$render_files"; \
	    fi; \
	done; \
	if [[ -s "$$render_files" ]]; then \
	  $(BOOTSTRAPPER) resolve-vars \
	    --vars-file resolve-vars.vars \
	    --file-list "$$render_files"; \
	fi

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


render-files:
	$(NO_ECHO)printf '%s\n' $(SOURCE_FILES_IN) > $@

.PHONY: test-resolver
test-resolver: render-files
	$(call gen-vars-file,$@.vars)
	time cmb resolve-vars --vars-file $@.vars --file-list $<

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
	$(NO_ECHO)$(BOOTSTRAPPER) create-deps > $@.tmp \
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


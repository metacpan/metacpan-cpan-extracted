#
# ENVIRONMENTS
#
# XLATE_DEBUG:  Enable debug output
# XLATE_MAXLEN: Set maximum length for API call
# XLATE_USEAPI: Use API
# XLATE_UPDATE: Force update cache
# XLATE_ANONYMIZE:      Anonymization dictionary file
# XLATE_MARK:           Inline anonymization marks (1 or custom regex)
# XLATE_TEMPLATE:       Protect template expressions (1 or custom regex)
# XLATE_FRONTMATTER:    Exclude/anonymize YAML front matter
# XLATE_SEED:           Seed cache from another cache file
# XLATE_CONTEXT_WINDOW: Context blocks for re-translation
#
# XOPT single-quotes XLATE_ANONYMIZE/XLATE_MARK/XLATE_TEMPLATE/XLATE_SEED/
# XLATE_CONTEXT_WINDOW (and FILE.ANONYMIZE) so a value such as a custom
# --mark/--template regex containing parentheses survives /bin/sh
# unharmed.  This leaves residual limits:
#   - values must not contain a single quote (') -- there is no escaping
#     for it inside the single-quoted recipe argument;
#   - a literal $ in a value must be written as $$ at the make layer,
#     or make will try to expand it as its own variable reference;
#   - REMOVE_QUOTE (below) strips embedded double quotes from these
#     variables before XOPT ever sees them, so double quotes in a value
#     do not need separate handling here.
#

#
# PARAMETER FILES
#   If the source file is acompanied with parameter files with
#   following extension, they are used to override default parameters.
#
# .LANG:   Languages translated to
# .FORMAT: Format of output files
# .ANONYMIZE: Anonymization dictionary for the file
#

XLATE_FORMAT ?= xtxt cm
XLATE_ENGINE ?= gpt5

ifeq ($(strip $(XLATE_FILES)),)
override XLATE_FILES := \
	$(filter-out README.%.md,\
	$(wildcard *.docx *.pptx *.txt *.md *.pm *.pod))
else
override XLATE_FILES := $(subst |||, ,$(XLATE_FILES))
endif

comma:=,
override XLATE_LANG := $(subst $(comma), ,$(XLATE_LANG))

# GNU Make treat strings containing double quotes differently on versions
define REMOVE_QUOTE
  override $1 := $$(subst ",,$$($1))
endef
$(foreach name,XLATE_LANG XLATE_FORMAT XLATE_FILES \
	XLATE_ANONYMIZE XLATE_MARK XLATE_TEMPLATE \
	XLATE_FRONTMATTER XLATE_SEED XLATE_CONTEXT_WINDOW,\
	$(eval $(call REMOVE_QUOTE,$(name))))

define FOREACH
$(foreach file,$(XLATE_FILES),
$(foreach lang,$(or $(shell cat $(file).LANG 2> /dev/null),$(XLATE_LANG)),
$(foreach form,$(or $(shell cat $(file).FORMAT 2> /dev/null),$(XLATE_FORMAT)),
$(foreach ecnt,$(words $(or $(shell cat $(file).ENGINE 2> /dev/null),$(XLATE_ENGINE))),
$(foreach engn,$(or $(shell cat $(file).ENGINE 2> /dev/null),$(XLATE_ENGINE)),
$(call $1,$(lang),$(form),$(file),$(engn),$(if $(ELIMINATE_LANG_PART),$(ecnt),99))
)))))
endef

define ADD_TARGET
ifeq ($5,1)
  TARGET += $$(addsuffix .$1.$2,$$(basename $3))
else
  TARGET += $$(addsuffix .$4-$1.$2,$$(basename $3))
endif
endef
$(eval $(call FOREACH,ADD_TARGET))

ALL := $(TARGET)

ALL: $(ALL)

TEXTCONV := optex -Mtc cat
CONVERT += doc docx pptx xlsx
CONVERT += pdf
SRCEXT  = stxt
$(foreach ext,$(CONVERT),$(eval \
  %.$(SRCEXT): %.$(ext) ; $$(TEXTCONV) $$< > $$@ \
))

STXT = $(if $(findstring $(suffix $1),$(CONVERT:%=.%)),$(basename $1).$(SRCEXT))
TEMPFILES += $(foreach file,$(XLATE_FILES),$(call STXT,$(file)))

define DEFINE_RULE
ifeq ($5,1)
$(basename $3).$1.$2: $3 $(call STXT,$3)
	$$(XLATE) $$(call XOPT,$3) -e $4 -t $1 -o $2 $$< > $$@
else
$(basename $3).$4-$1.$2: $3 $(call STXT,$3)
	$$(XLATE) $$(call XOPT,$3) -e $4 -t $1 -o $2 $$< > $$@
endif
endef
$(eval $(call FOREACH,DEFINE_RULE))

XLATE = xlate \
	$(if $(XLATE_DEBUG),-d) \
	$(if $(XLATE_MAXLEN),-m$(XLATE_MAXLEN)) \
	$(if $(XLATE_USEAPI),-a) \
	$(if $(XLATE_UPDATE),-u)

XOPT = $(if $(wildcard $1.ANONYMIZE),--anonymize='$1.ANONYMIZE',\
	$(if $(XLATE_ANONYMIZE),--anonymize='$(XLATE_ANONYMIZE)')) \
	$(if $(XLATE_MARK),$(if $(filter 1,$(XLATE_MARK)),--mark,--mark='$(XLATE_MARK)')) \
	$(if $(XLATE_TEMPLATE),$(if $(filter 1,$(XLATE_TEMPLATE)),--template,--template='$(XLATE_TEMPLATE)')) \
	$(if $(XLATE_FRONTMATTER),--frontmatter) \
	$(if $(XLATE_SEED),--seed='$(XLATE_SEED)') \
	$(if $(XLATE_CONTEXT_WINDOW),--context='$(XLATE_CONTEXT_WINDOW)')

.PHONY: clean
clean:
	rm -fr $(ALL) $(TEMPFILES)

#
# ENVIRONMENTS
#
# XLATE_DEBUG:  Enable debug output
# XLATE_MAXLEN: Set maximum length for API call
# XLATE_USEAPI: Use API
#

#
# PARAMETER FILES
#   If the source file is acompanied with parameter files with 
#   following extension, they are used to override default parameters.
#
# .LANG:   Languages translated to
# .FORMAT: Format of output files
#

XLATE_FORMAT ?= xtxt cm
XLATE_ENGINE ?= deepl

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
$(foreach name,XLATE_LANG XLATE_FORMAT XLATE_FILES,\
	$(eval $(call REMOVE_QUOTE,$(name))))

define FOREACH
$(foreach file,$(XLATE_FILES),
$(foreach lang,$(or $(shell cat $(file).LANG 2> /dev/null),$(XLATE_LANG)),
$(foreach form,$(or $(shell cat $(file).FORMAT 2> /dev/null),$(XLATE_FORMAT)),
$(foreach engn,$(or $(shell cat $(file).ENGINE 2> /dev/null),$(XLATE_ENGINE)),
$(call $1,$(lang),$(form),$(file),$(engn))
))))
endef

define ADD_TARGET
  TARGET += $$(addsuffix .$4-$1.$2,$$(basename $3))
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
$(basename $3).$4-$1.$2: $3 $(call STXT,$3)
	$$(XLATE) -e $4 -t $1 -o $2 $$< > $$@
endef
$(eval $(call FOREACH,DEFINE_RULE))

XLATE = xlate \
	$(if $(XLATE_DEBUG),-d) \
	$(if $(XLATE_MAXLEN),-m$(XLATE_MAXLEN)) \
	$(if $(XLATE_USEAPI),-a)

.PHONY: clean
clean:
	rm -fr $(ALL) $(TEMPFILES)

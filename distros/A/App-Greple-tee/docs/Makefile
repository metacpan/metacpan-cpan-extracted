.DELETE_ON_ERROR:

LANGS    := DE EL ES ET FR ID JA KO NL RO RU TR ZH AR
RM_LANGS :=                   JA KO             ZH
IGNORE   := VERSION AUTHOR LICENSE

ENGINES     := deepl gpt5
#LANGS_deepl := DE EL ES ET FR ID JA KO NL RO RU TR ZH
LANGS_gpt5  := JA KO ZH

MOD_NAME := $(shell perl -MJSON -0777nE 'say decode_json($$_)->{name}' ../META.json)
MOD_PATH := ../lib/$(subst -,/,$(MOD_NAME)).pm
MOD_FILE := $(notdir $(MOD_PATH))
MOD_DIR  := $(dir $(MOD_PATH))
MOD_NAME := $(MOD_FILE:.pm=)
SRC_DIR  := src

ORIGIN   := $(MOD_PATH)
PM       := $(notdir $(ORIGIN))
POD      := $(PM:.pm=.pod)
SRC      := $(POD:%=$(if $(SRC_DIR),$(SRC_DIR)/,)%)
###########
$(foreach E,$(ENGINES),\
$(foreach L,$(LANGS_$E),\
  $(eval PODS    += $(SRC:.pod=.$E-$L.pod))\
  $(eval MDS     += $(PM:.pm=.$E-$L.md))\
  $(eval READMES += $(if $(filter $L,$(RM_LANGS)),../README.$E-$L.md))\
))
###########
ALL      := $(PODS) $(MDS) README.md $(READMES)

all: $(ALL)

ifdef SRC_DIR
  $(SRC_DIR):
	mkdir -p $(SRC_DIR)
endif
SRCPATH := $(if $(SRC_DIR),$(SRC_DIR)/,)

GREPLE := perl -I../lib -S greple

PODIFY := $(GREPLE) -Mperl --nocolor --le :pod
$(foreach mod,$(ORIGIN),$(eval \
  $(SRCPATH)$(subst .pm,.pod,$(notdir $(mod))): $(mod) Makefile; $(PODIFY) $$< > $$@ \
))

XLATE := $(GREPLE) -Mxlate
XLATE += $(if $(XLATE_LABOR),--xlate-labor,--xlate)
XLATE += --xlate-cache=$(if $(XLATE_INIT),clear,yes)
XLATE += --match-podtext --xlate-format=none --all --need=0

MASKFILE=PATTERN_MASK
ifneq ($(wildcard $(MASKFILE)),)
XLATE += --xlate-setopt maskfile=$(MASKFILE)
endif

CONTEXTFILE=CONTEXT.md
ifneq ($(wildcard $(CONTEXTFILE)),)
XLATE += --xlate-context "$$(cat $(CONTEXTFILE))"
endif

ifdef IGNORE
$(foreach ignore,$(IGNORE),$(eval \
  XLATE += --exclude '^=head\d[ ]+(?i:$(ignore))\b(?s:.*?)(?=^=|\z)'\
))
endif

deepl_JA_FORM   ?= desumasu
deepl_JA_DICT   := $(wildcard *.dict)
deepl_JA_FILTER := $(GREPLE) -Mperl -Msubst::desumasu \
	$(if $(findstring $(deepl_JA_FORM).dict,$(deepl_JA_DICT)),--dict $(deepl_JA_FORM).dict) \
	--pod --subst --all --no-color --need=0 \
	--$(deepl_JA_FORM) 

define LANG_POD
  $(SRCPATH)%.$2-$1.pod: $(SRCPATH)%.pod Makefile
  ifdef $2_$1_FILTER
	$$(XLATE) --xlate-engine=$2 --xlate-to $1 $$< | $$($2_$1_FILTER) > $$@
  else
	$$(XLATE) --xlate-engine=$2 --xlate-to $1 $$< > $$@
  endif
endef

$(foreach E,$(ENGINES),$(foreach L,$(LANGS),$(eval $(call LANG_POD,$L,$E))))

%.md: $(SRCPATH)%.pod
	pod2markdown $< > $@

define LANG_README
  ../README.$2-$1.md: $(MOD_NAME).$2-$1.md
	cp $$< $$@
endef

$(foreach E,$(ENGINES),\
$(foreach L,$(LANGS),\
  $(eval $(call LANG_README,$L,$E))\
))

README.md: Makefile
	exec > $@ && \
	printf '## Languages\n\n' && \
	for md in $(MDS) ; \
	do \
	    echo "- [$$md]($$md)" ; \
	done

clean:
	rm -f $(SRC) $(ALL)

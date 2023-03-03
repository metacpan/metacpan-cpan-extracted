LANGS    := DE EL ET FR ID JA KO NL RO RU TR UK ZH
RM_LANGS := JA KO ZH
IGNORE   := AUTHOR LICENSE

LIB    := ../lib/App/Greple
SRCDIR := src

MODS   := $(wildcard $(LIB)/*.pm)
PM     := $(notdir $(MODS))
NAME   := $(patsubst %.pm,%,$(firstword $(PM)))
SRC    := $(PM:%=$(if $(SRCDIR),$(SRCDIR)/,)%)
PMS    := $(foreach lang,$(LANGS),$(SRC:.pm=.$(lang).pm))
MDS    := $(foreach lang,$(LANGS),$(PM:.pm=.$(lang).md))
RM_MDS := $(RM_LANGS:%=../README.%.md)
ALL    := $(PMS) $(MDS) README.md $(RM_MDS)

all: $(ALL)

ifdef SRCDIR
  $(SRCDIR):
	mkdir -p $(SRCDIR)
endif
SRCPATH := $(if $(SRCDIR),$(SRCDIR)/,)

$(foreach mod,$(MODS),$(eval $(SRCPATH)$(notdir $(mod)): $(mod); cp $$< $(if $(SRCPATH),$(SRCPATH),.) ))

XLATE := greple -Mxlate::deepl --match-podtext --xlate-format=none --xlate --xlate-cache=yes --all

ifdef IGNORE
$(foreach ignore,$(IGNORE),$(eval \
  XLATE += --exclude '^=head\d[ ]+$(ignore)\b(?s:.*?)(?=^=|\z)'\
))
endif

JA_FORM   ?= dearu
JA_DICT   := $(wildcard *.dict)
JA_FILTER := greple -Mperl -Msubst::desumasu \
	$(if $(findstring $(JA_FORM).dict,$(JA_DICT)), --dict $(JA_FORM).dict) \
	--pod --subst --all --no-color --need=0 \
	--$(JA_FORM) 

define LANG_PM
  $(SRCPATH)%.$1.pm: $(SRCPATH)%.pm Makefile
  ifdef $1_FILTER
	$$(XLATE) --xlate-to $1 $$< | $$($1_FILTER) > $$@
  else
	$$(XLATE) --xlate-to $1 $$< > $$@
  endif
endef

$(foreach lang,$(LANGS),$(eval $(call LANG_PM,$(lang))))

%.md: $(SRCPATH)%.pm
	pod2markdown $< > $@

define LANG_README
  ../README.$1.md: $(NAME).$1.md
	cp $$< $$@
endef

$(foreach lang,$(RM_LANGS),$(eval $(call LANG_README,$(lang))))

README.md: Makefile
	exec > $@ && \
	printf '## Languages\n\n' && \
	for md in $(MDS) ; \
	do \
	    echo "- [$$md]($$md)" ; \
	done

clean:
	rm -f $(SRC) $(ALL)

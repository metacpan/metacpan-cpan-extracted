LANGS    := DE EL ET FR ID JA KO NL RO RU TR UK ZH
RM_LANGS := JA KO ZH
IGNORE   := VERSION AUTHOR LICENSE

LIB    := ../lib/App/Greple
SRCDIR := src

MODS   := $(wildcard $(LIB)/*.pm)
PM     := $(notdir $(MODS))
POD    := $(PM:.pm=.pod)
NAME   := $(patsubst %.pm,%,$(firstword $(PM)))
SRC    := $(POD:%=$(if $(SRCDIR),$(SRCDIR)/,)%)
PODS   := $(foreach lang,$(LANGS),$(SRC:.pod=.$(lang).pod))
MDS    := $(foreach lang,$(LANGS),$(POD:.pod=.$(lang).md))
RM_MDS := $(RM_LANGS:%=../README.%.md)
ALL    := $(PODS) $(MDS) README.md $(RM_MDS)

all: $(ALL)

ifdef SRCDIR
  $(SRCDIR):
	mkdir -p $(SRCDIR)
endif
SRCPATH := $(if $(SRCDIR),$(SRCDIR)/,)

PODIFY := greple -Mperl --nocolor --le :pod
$(foreach mod,$(MODS),$(eval \
  $(SRCPATH)$(subst .pm,.pod,$(notdir $(mod))): $(mod) Makefile; $(PODIFY) $$< > $$@ \
))

ifdef IGNORE
$(foreach ignore,$(IGNORE),$(eval \
  EXCLUDE += --exclude '^=head\d[ ]+(?i:$(ignore))\b(?s:.*?)(?=^=|\z)'\
))
endif

XLATE := xlate $(if $(USEAPI),-a)

DESUMASU := NO
ifeq ($(DESUMASU),GREPLE)
JA_FORM   ?= dearu
JA_DICT   := $(wildcard *.dict)
JA_FILTER := greple -Mperl -Msubst::desumasu \
	$(if $(findstring $(JA_FORM).dict,$(JA_DICT)), --dict $(JA_FORM).dict) \
	--pod --subst --all --no-color --need=0 \
	--$(JA_FORM)
endif
ifeq ($(DESUMASU),GPTY)
JA_FILTER := perl -I../lib -S greple \
	-Mtee gpty -d -q -t 0 \
		-s '以下の項目に挙げる指示にしたがって、続く日本語の文章を変換してください' \
		-s '語尾がない文については付け加えずにそのままにする' \
		-s '語尾の部分だけを「である調」から「ですます調」に換える' \
		- -- \
	-Mperl --pod -E '^(\w.*\n)+' \
	--discrete --bulkmode \
	$(EXCLUDE) \
	--all --no-color
endif

define LANG_POD
  $(SRCPATH)%.$1.pod: $(SRCPATH)%.pod Makefile
  ifdef $1_FILTER
	$$(XLATE) -t $1 $$< | $$($1_FILTER) > $$@
  else
	$$(XLATE) -t $1 $$< > $$@
  endif
endef

$(foreach lang,$(LANGS),$(eval $(call LANG_POD,$(lang))))

%.md: $(SRCPATH)%.pod
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

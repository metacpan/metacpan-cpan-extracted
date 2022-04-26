#
# VARIABLES
#   BOUNDARY
#	DEFAULT : \pP
#	BORDER  : \b
#	JPUNCT   : [。、（）()])
#
BOUNDARY?=JPUNCT

ORIGINAL := desumasu-converter.base
NAME     := dearu desumasu
BASE     := $(NAME:=.base)
DEFAULT  := $(NAME:=.dict)
KEEP     := $(NAME:=-keep-ne.dict)
IGNORE   := $(NAME:=-ignore-ne.dict)
ALL      := $(BASE) $(DEFAULT) $(KEEP) $(IGNORE)

all: $(ALL)

clean:
	rm -f $(ALL)

PERL=perl -CSDA -Mutf8

ifeq ($(BOUNDARY),BORDER)
BOUNDARY_REGEX=\\b
else ifeq ($(BOUNDARY),JPUNCT)
BOUNDARY_REGEX=(?=[。、（）()])
else
BOUNDARY_REGEX=(?=\\pP)
endif

dearu.base: $(ORIGINAL) reorder.pl Makefile
	awk '{ print $$1 "  " $$2 }' $< | column -t | $(PERL) reorder.pl > $@

desumasu.base: $(ORIGINAL) reorder.pl Makefile
	awk 'length($$3)==0 { print $$2 "  " $$1 }' $< | column -t | $(PERL) reorder.pl > $@

%.dict: %.base Makefile
	$(PERL) -p -E 's/(?=\s)/ね?$(BOUNDARY_REGEX)/' $< > $@

%-keep-ne.dict: %.base Makefile
	$(PERL) -p -E 's/(?=\s)/(?=ね?$(BOUNDARY_REGEX))/' $< > $@

%-ignore-ne.dict: %.base Makefile
	$(PERL) -p -E 's/(?=\s)/$(BOUNDARY_REGEX)/' $< > $@

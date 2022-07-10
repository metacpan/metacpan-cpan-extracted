DOCX  = $(filter-out ~%,$(wildcard *.docx))
NAME  = $(basename $(DOCX))

DIFF  = $(NAME:=.diff)
STAT  = $(NAME:=.stat)
PATCH = $(NAME:=.patch)
SJIS  = $(PATCH:=.sjis)

ALL = $(DIFF) $(STAT) $(PATCH)

all: $(ALL)

sjis: $(SJIS)

$(ALL): Makefile

clean:
	rm -f $(ALL) $(SJIS)

GREPLE = greple --norc -Mmsdoc -Msubst --check=any
DIFF2VBA = perl -I../lib ../script/diff2vba

%.diff: %.docx
	$(GREPLE) --all-sample-dict --diff $< | sed 1,2d > $@

%.stat: %.docx
	TERM_BGCOLOR=555 $(GREPLE) --color=always --all-sample-dict --stat $< > $@

%.patch: %.diff
	$(DIFF2VBA) $< > $@

%patch.sjis: %patch
	iconv -f utf8 -t sjis < $< > $@

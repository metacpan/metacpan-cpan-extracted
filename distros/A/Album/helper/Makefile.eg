# Generic Makefile for albums.

BASE    = $(notdir ${PWD})

TOOLS	 = $(HOME)/src/album/src
DATA	 = $(HOME)/src/album/data

_DCIM    := dcim
_DCF     := 101msdcf
DCIM	 ?= ${_DCIM}/${_DCF}
RAW	 ?= ${DCIM}

OPTS	 ?=
PERL	 ?= perl
ALBUMCMD := $(PERL) -w $(TOOLS)/album.pl $(OPTS) --verbose

ifdef TARGET
default upload :: to-${TARGET}
else
default :: update update-ll
endif

################ ALBUM ################

IMPORT ?= $(shell test -d $(RAW) && echo "--dcim=$(RAW)")

update ::
	${ALBUMCMD} --update $(IMPORT)

update-ll ::
	perl ${TOOLS}/updatellink.pl

clobber ::
	${ALBUMCMD} --clobber --update $(IMPORT)

merge ::
	$(PERL) $(TOOLS)/merge.pl info.dat > x~
	if cmp info.dat x~ >/dev/null; then \
	  rm -f x~; \
	else \
	  cp -p info.dat info.dat~ && cp -p x~ info.dat && rm x~; \
	fi

################ SETUP ################

init ::
	mkdir -p $(DCIM)
	test -f Makefile || echo "include $(TOOLS)/generic.mk" > Makefile
	test -f info.dat || { \
		dir="`basename \`pwd\``"; \
		touch $(DATA)/$$dir.dat; \
		ln -s $(DATA)/$$dir.dat info.dat; \
		echo "!title $$dir" > info.dat; \
	}

clean ::
	rm -f .cache *png index*html large/*html *~
	rm -f shellrun.exe ShellRun.exe autorun.inf
	rm -fr icons css images medium thumbnails .xvpics

realclean :: clean
	rm -f `readlink info.dat` info.dat 

################ PAR2 ################

par2 ::
	cd dcim; \
	rm -fr .xvpics; \
	par2 c -R ${BASE} 101msdcf

################ FETCH ################

WIFIDEV := tz200
POWEROFF :=

fetch ::	fetch_${WIFIDEV}

fetch_tz200 ::
	perl ${HOME}/src/Lumix-Tools/scripts/fetch.pl \
	     --path=${RAW} --exclude='????0001.jpg' ${POWEROFF}; \

################ EXPORT ################

WCAPTION ?= tc

export-web ::
	${ALBUMCMD} --mediumonly --caption=$(WCAPTION)
	rm -f web.zip
	zip -rn .jpg web.zip index*.html icons css medium index journal

################ UPLOADING ################

RESINFO := resinfo

# Rsync filter to copy all images, omitting -- and movies.
.filter : info.dat
	perl -ne 'END{print"- *\n"} print "+ /$$1\n" if /^(\S+\.(?:jpg|png|webp))/ && !/\s+--\s/' $< > $@

define define_uploader
to-$(1) to_$(1) : .filter ;
	rsync -virltD --modify-window=3601 \
	  --delete --delete-excluded --filter=". .filter" \
	  large/ \
	  $(1):$(shell ${RESINFO} albums.$(1).path)/${BASE}/
endef

ifdef TARGET
$(call define_uploader,${TARGET})
else
TARGETS := glaxxy glaxs4 glaxs7 glaxa8 largo
$(foreach host,${TARGETS},$(call define_uploader,$(host)))
endif

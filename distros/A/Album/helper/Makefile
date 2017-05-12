# Generic Makefile for albums.

HERE	= .
TOOLS	= $(HOME)/src/album/src
DATA	= $(HOME)/src/album/data
CAMERA	= /mnt/camera
DCIM	= dcim/101msdcf
DSC	= $(CAMERA)/$(DCIM)
RAW	= $(HERE)/$(DCIM)
OPTS	=
PERL	= perl

IMPORT	= $(shell test -d $(DCIM) && echo "--dcim=$(DCIM)")

default : update

fetch :	mountc _fetch umountc

mountc :
	-mount $(CAMERA)

_fetch :
	rsync -av --modify-window=1 --exclude=dsc00000.jpg \
	    $(DSC)/ $(RAW)/
	find $(RAW) -type f -perm +333 -print -exec chmod 0444 {} \;

umountc :
	-umount $(CAMERA)

update :
	$(PERL) -w $(TOOLS)/album.pl $(OPTS) --verbose --update $(IMPORT) $(HERE)

clobber :
	$(PERL) -w $(TOOLS)/album.pl $(OPTS) --verbose --clobber --update $(IMPORT) $(HERE)

export-web :
	$(PERL) -w $(TOOLS)/album.pl $(OPTS) --verbose --mediumonly --caption=tc $(HERE)
	rm -f web.zip
	zip -r web.zip index*.html icons css medium thumbnails journal

init ::
	mkdir -p $(DCIM)
	ln -s $(TOOLS)/shellrun.exe .
	ln -s $(TOOLS)/autorun.inf .
	test -f Makefile || ln -s $(TOOLS)/generic.mk Makefile
	test -f info.dat || { \
		dir="`basename \`pwd\``"; \
		touch $(DATA)/$$dir.dat; \
		ln -s $(DATA)/$$dir.dat info.dat; \
		echo "!title $$dir" > info.dat; \
	}

init-nolinks ::
	mkdir -p $(DCIM)
	cp $(TOOLS)/shellrun.exe .
	cp $(TOOLS)/autorun.inf .
	test -f Makefile || cp $(TOOLS)/generic.mk Makefile
	test -f info.dat || { \
		dir="`basename \`pwd\``"; \
		echo "!title $$dir" > info.dat; \
	}

clean ::
	rm -f .cache *png index*html large/*html *~
	rm -f shellrun.exe ShellRun.exe autorun.inf
	rm -fr icons css images medium thumbnails .xvpics

realclean :: clean
	rm -f `readlink info.dat` info.dat 

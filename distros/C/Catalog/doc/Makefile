include ../conf/install.conf

all: $(doc_all)

all_info: catalog.info

all_html: catalog_toc.html

all_ps: catalog.ps

IMAGES_GIF = $(shell find images/*.gif -print | grep -v images/fct)
IMAGES_EPS = $(patsubst %.gif,%.eps,$(IMAGES_GIF))
IMAGES_TXT = $(patsubst %.gif,%.txt,$(IMAGES_GIF))

catalog.ps: catalog.texinfo $(IMAGES_EPS) $(IMAGES_TXT)
	$(texi2dvi) catalog.texinfo
	$(dvips) -o catalog.ps catalog.dvi

catalog_toc.html: catalog.texinfo
	rm -fr tmp ; mkdir tmp ; cd tmp ; ln -s ../images .
	perl -p -e 's/^\s*\@/\@/' < catalog.texinfo > tmp/catalog.texinfo
	cd tmp ; perl $(texi2html) -acc -split_node catalog.texinfo ; rm catalog.texinfo images ; mv * ..
	rm -fr tmp

#
# makeinfo 3.12 dumps core on @image
#
catalog.info: catalog.texinfo # $(IMAGES_TXT)
	grep -v '@image' < catalog.texinfo > c.texinfo 
	$(makeinfo) c.texinfo
	rm -f c.texinfo

install: $(doc_install)

install_info: all_info
	cp catalog.info* $(infodir)
	if [ -w $(infodir)/dir ] ; \
	then \
		if grep 'Catalog:' $(infodir)/dir > /dev/null ; \
		then : ; \
		else \
			if [ ! -f $(infodir)/dir.gz -o -w $(infodir)/dir.gz ] ; \
			then \
				echo '* Catalog: (catalog)	HTML based resource directory builder' >> $(infodir)/dir ; \
				if [ -f $(infodir)/dir.gz ] ; \
				then \
					gzip < $(infodir)/dir > $(infodir)/dir.gz ; \
				fi ; \
			fi ; \
		fi ; \
	fi

install_html: all_html 
	cp catalog_*.html $(htmldir)
	if [ ! -d $(htmldir)/images ] ; then mkdir -p $(htmldir)/images ; fi
	cp images/*.gif $(htmldir)/images

install_ps:

clean:
	rm -f catalog.aux catalog.cp catalog.dvi catalog.fn 
	rm -f catalog.info*
	rm -f catalog.ky catalog.log catalog.pg catalog.ps
	rm -f catalog.toc catalog.tp catalog.vr catalog.cps catalog.fns
	rm -f catalog_*.html catalog.info-? texput.log
	rm -f $(IMAGES_EPS) $(IMAGES_TXT)
	rm -fr tmp

fctimages:
	pstopnm -xsize 1000 -portrait images/fctcatalog.eps 
	ppmtogif < fctcatalog.eps001.ppm > images/fctcatalog.gif
	rm -f fctcatalog.eps001.ppm
	echo "[fctcatalog image]" > images/fctcatalog.txt
	pstopnm -portrait images/fctsqledit.eps 
	ppmtogif < fctsqledit.eps001.ppm > images/fctsqledit.gif
	rm -f fctsqledit.eps001.ppm
	echo "[fctslqedit image]" > images/fctsqledit.txt

realclean:

test:

%.eps:%.gif
	giftopnm < $*.gif | pnmtops -rle -noturn > $*.eps

%.txt:%.gif
	echo "[$* image]" > $*.txt

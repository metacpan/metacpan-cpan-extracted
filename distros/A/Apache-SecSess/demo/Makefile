#
# Makefile - install demo for Apache::SecSess
#
# $Id: Makefile,v 1.3 2002/05/08 02:14:59 pliam Exp $
#

help:
	@echo type "'make install'" to install demo files
	@echo WARNING: This will destroy your existing configuration.

#
# attend to these definitions before make install
#
APACHEROOT=/usr/local/apache
HTROOT=$(APACHEROOT)/ht
APACHECONF=$(APACHEROOT)/conf
SECRET=Rough winds do shake the darling buds of May

#
# these should be left alone unless you change some code
#
MASTER=httpd.conf
STARTUP=startup.pl
SHORT=sec1 sec2 perl adam lysander tom john milt noam stu 
PRIVATE=$(APACHECONF)/private
SECFILE=$(PRIVATE)/ckysec.txt

#
# install target
#
install:
	(cd ht; tar cf - *.comp *.com *.org images | (cd $(HTROOT); tar xvf -))
	install -m 0644 httpdconf/$(MASTER) $(APACHECONF)
	install -m 0644 httpdconf/$(STARTUP) $(APACHECONF)
	for c in $(SHORT); \
		do install -m 0644 httpdconf/httpd.$$c.conf $(APACHECONF); \
	done
	mkdir -p $(PRIVATE)
	echo $(SECRET) > $(SECFILE)
	chmod -R go-rwX $(PRIVATE)

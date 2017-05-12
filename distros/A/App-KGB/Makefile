#!/usr/bin/make -f

PERL ?= /usr/bin/perl

Build: Build.PL
	$(PERL) $<

all: build

build install test manifest distcheck: Build
	./Build $@

orig: distclean
	[ ! -e debian/rules ] || $(MAKE) -f debian/rules clean
	$(MAKE) Build
	./Build $@

dist: manifest distcheck
	./Build $@

clean:
	[ ! -e Build ] || ./Build $@

realclean distclean:
	[ ! -e Build ] || ./Build $@
	rm -f MANIFEST.bak App-KGB-*.*.tar.gz

# vim: noet

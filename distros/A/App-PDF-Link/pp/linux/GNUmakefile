#! /bin/make -f
# GNUmakefile for Linux + CitrusPerl
# Based on CitrusPerl 5.24 with wxWidgets 3.0.

.PHONY : pdflink

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script

# Perlbrew for CitrusPerl.
PP := perl -Ilib/perl5 -Mlocal::lib=lib/perl5 bin/pp
WXLIBS := /bulk/perlbrew/perls/citrus-5.24.1-wx-3.0/vendor/lib/Alien/wxWidgets/gtk_3_0_2_uni/lib

pdflink :  pdflink.pp ${COMMON}/pdflink.pp
	${PP} --output=pdflink @pdflink.pp ${SCRIPT}/pdflink.pl

clean ::
	rm -f *.pp.deps *~ pdflink

#! /bin/make -f
# GNUmakefile for Linux

.PHONY : pdflink

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script

PP := pp

pdflink :  pdflink.pp ${COMMON}/pdflink.pp
	${PP} --output=pdflink @pdflink.pp ${SCRIPT}/pdflink.pl

clean ::
	rm -f *.pp.deps *~ pdflink

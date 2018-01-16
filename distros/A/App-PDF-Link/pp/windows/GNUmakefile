# gmake file for MS Windows + CitrusPerl
# Based on 64-bit gmake and CitrusPerl 5.24 with wxWidgets 3.0.

SCRIPT := ../../script

.ONESHELL :

PP := pp

pdflink.exe :: pdflink.pp
	${PP} --output=pdflink.exe @pdflink.pp ${SCRIPT}/pdflink.pl

clean ::
	del pdflink.exe  *.pp.deps

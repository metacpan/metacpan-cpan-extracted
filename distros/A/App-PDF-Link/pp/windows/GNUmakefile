# gmake file for MS Windows + StrawberryPerl

SCRIPT := ../../script

.ONESHELL :

PP := pp

pdflink.exe :: pdflink.pp
	${PP} --output=pdflink.exe @pdflink.pp ${SCRIPT}/pdflink.pl

clean ::
	del pdflink.exe  *.pp.deps

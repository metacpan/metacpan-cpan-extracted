#! /bin/make -f

PERL := perl
PROJECT := PDFlink
TMP_DST := ${HOME}/tmp/${PROJECT}

to_tmp : 
	rsync -avH --files-from=../MANIFEST ../ ${TMP_DST}/

to_tmp_cpan :
	rsync -avH --files-from=MANIFEST.CPAN ../ ${TMP_DST}/


DOCDIR=pod-html


package:

	perl Makefile.PL
	make
	#make test
#	make install

	make html -f make.mk

html:

	pod2html ./Perform/Widgets/ButtonSet.pm         > $(DOCDIR)/DBIx-Perform-Widgets-ButtonSet.html
	pod2html ./Perform/Widgets/TextField.pm         > $(DOCDIR)/DBIx-Perform-Widgets-TextField.html
	pod2html ./Perform/DButils.pm                   > $(DOCDIR)/DBIx-Perform-DButils.html
	pod2html ./Perform/DigestPer.pm                 > $(DOCDIR)/DBIx-Perform-DigestPer.html
	pod2html ./Perform/Forms.pm                     > $(DOCDIR)/DBIx-Perform-Forms.html
	pod2html ./Perform.pm                           > $(DOCDIR)/DBIx-Perform-Perform.html

clean:

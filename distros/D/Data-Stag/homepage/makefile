FMTS = html pdf rtf ps
FILES = $(patsubst %,dbstag-tutorial.%, $(FMTS))

all: $(FILES)
test:
	echo $(FILES)
%.html: dbstag-tutorial.sgml
	db2html --nochunks $*.sgml > $@.tmp && mv $@.tmp $@

dbstag-tutorial.%: dbstag-tutorial.sgml
	db2$* dbstag-tutorial.sgml

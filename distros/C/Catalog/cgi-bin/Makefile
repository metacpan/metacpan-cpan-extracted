include ../conf/install.conf

EXE = Catalog dmoz

all: $(EXE)

#
# Non GNU make need this before implicit rule
#
.SUFFIXES: .PL

.PL:
	@perl $<

install:
	for i in $(EXE) ; do \
	  rm -f $(cgidir)/$$i ; \
	  cp $$i $(cgidir) ; \
	  chmod +x $(cgidir)/$$i ; \
	done

clean:
	rm -f *~

realclean:
	rm -f $(EXE)

test:

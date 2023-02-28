DESUMASU = perl -Ilib -S greple -Msubst::desumasu --no-color --subst --all

ALL := t2-s.txt t2-r.txt t3-r.txt t4-r.txt

all: $(ALL)

t2-s.txt: t1-s.txt Makefile
	(cd ..; $(DESUMASU) --dearu t/$<) > $@

t2-r.txt: t2-s.txt Makefile
	(cd ..; $(DESUMASU) --desumasu t/$<) > $@

t3-r.txt: t1-s.txt Makefile
	(cd ..; $(DESUMASU) --dearu-n t/$<) > $@

t4-r.txt: t1-s.txt Makefile
	(cd ..; $(DESUMASU) --dearu-N t/$<) > $@

.PHONY: clean
clean:
	rm -f $(ALL)

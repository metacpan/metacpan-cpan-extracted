inputs:=$(wildcard *.dot)
machines=$(foreach f,$(inputs),$(basename $f))
modules=$(foreach m,$(machines),$(m).pm)
psfiles=$(foreach m,$(machines),$(m).ps)
libdir=../lib/Cluster/Init

all: $(psfiles) $(modules) 

clean:
	rm -f $(psfiles) $(modules)

%.pm: %.dot 
	./dot2dfa -u $? > $@	
	perl -c $@

%.ps: %.dot
	dot -Tps $? > $@

install: $(modules) $(psfiles)
	install -d $(libdir)/DFA
	install $(modules) $(libdir)/DFA


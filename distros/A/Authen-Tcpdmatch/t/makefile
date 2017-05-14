.PHONY:    $(shell ls)
.SILENT:

#PERL = /usr/bin/perl

OPTS     =  -lw -Mblib
MODULES  =  -Mstrict  -MData::Dumper -MCarp

#  00_basic.t       01_byname.t     02_wildcard.t
#  03_ip_dot.t      04_dot_ip.t     05_netmask.t
#  06_multiline.t   07_tcpdmatch.t  pod.t  pod-coverage.t

#all: bench.pl
#all: 00_basic.t
#all: 07_tcpdmatch.t

vim = vi -p -c 'set nofoldenable'

current = 01c_coverage.t
current = 00_load.t
current = 01s_spelling.t

all: $(current)
#all: pod-coverage.t

p* t*t 0*t:
	perl $(OPTS) $(MODULES) $@
doc:
	perldoc -F ../lib/Authen/Tcpdmatch/Tcpdmatch.pm
w:
	chmod +w  ../blib/lib/Authen/Tcpdmatch/Tcpdmatch.pm
cp:
	cp ../blib/lib/Authen/Tcpdmatch/* ../lib/Authen/Tcpdmatch
vi:
	$(vim) $(current) ../blib/lib/Authen/Tcpdmatch/Tcpdmatch.pm
test:
	make -sC .. test
bench:
	$(PERL) $(OPTS)  $(MODULES) ../scripts/$@.pl
help:
	echo bench vi cp test
	

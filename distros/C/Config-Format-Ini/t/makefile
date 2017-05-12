# 00_load.t     01a_pod.t         01b_pod.t         01c_coverage.t
# 02_basic.t    03_grammar.t      04_values.t       05_comments.t
# 06_resync.t   07_escapes.t      08_continuation.t


.PHONY: $(shell ls)

OPTS = -Mstrict -MData::Dumper -Mblib=../blib 

#all: 08_continuation.t
all: 09_simplify.t
#all: 01c_coverage.t

P* 0*:
	@perl -lw  $(OPTS) $@
w:
	chmod -R +w ../blib/lib/Config
pod:
	perldoc ../blib/lib/Config/Format/Ini.pm
	#perldoc ../blib/lib/Config/Format/Ini/Grammar.pm
ls:
	ls -l ../blib/lib/Config

vi: w
	vim ../blib/lib/Config/Format/Ini.pm
vig:
	vim ../blib/lib/Config/Format/Ini/Grammar.pm
cp:
	cp ../blib/lib/Config/Format/Ini.pm        ../lib/Config/Format
	cp ../blib/lib/Config/Format/Ini/*         ../lib/Config/Format/Ini
precompile:
	 perl -MParse::RecDescent - grammar  Config::Format::Init::Gram

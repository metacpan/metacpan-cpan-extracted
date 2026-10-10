#-*- mode: makefile; -*-

test-requires: test-requires.raw
test-requires.raw: test-requires.scan
test-requires.scan: $(TESTS)

test-requires.cpanfile: test-requires
	$(NO_ECHO)$(CPAN_MAKER) create-cpanfile --dependency-type requires $< -o $@

.PHONY: test-local
test-local::

.PHONY: test
test: $(GSOURCE_FILES) test-local | local/.installed ## run unit tests
	PERL5LIB= prove -I lib -I local/lib/perl5 -v t/
	test -z "$(AUTHOR_TESTING)" || $(MAKE) test-author
	test -z "$(RELEASE_TESTING)" || $(MAKE) test-release
	test -z "$(AUTOMATED_TESTING)" || $(MAKE) test-smoke

.PHONY: test-all
test-all: $(GSOURCE_FILES) | local/.installed ## run all tests
	$(MAKE) test \
	  AUTHOR_TESTING=1 \
	  RELEASE_TESTING=1 \
	  AUTOMATED_TESTING=1

check: $(GSOURCE_FILES) ## syntax check and create source from .in file

.PHONY: test-author
test-author:: | local/.installed ## author tests
	$(NO_ECHO)mkdir -p xt/author; \
	PERL5LIB= prove -I lib -I local/lib/perl5 -r xt/author

.PHONY: test-release
test-release:: | local/.installed ## release tests
	$(NO_ECHO)mkdir -p xt/release; \
	PERL5LIB= prove -I lib -I local/lib/perl5 -r xt/release

.PHONY: test-smoke
test-smoke:: | local/.installed ## smoke tests
	$(NO_ECHO)mkdir -p xt/smoke; \
	PERL5LIB= prove -I lib -I local/lib/perl5 -r xt/smoke

#-*- mode: makefile; -*-

.PHONY: test-local
test-local::

.PHONY: test
test: $(GSOURCE_FILES) test-local ## run unit tests
	PERL5LIB= prove -I lib -I local/lib/perl5 -v t/
	test -z "$(AUTHOR_TESTING)" || $(MAKE) test-author
	test -z "$(RELEASE_TESTING)" || $(MAKE) test-release
	test -z "$(AUTOMATED_TESTING)" || $(MAKE) test-smoke

.PHONY: test-all
test-all: $(GSOURCE_FILES) ## run all tests
	$(MAKE) test \
	  AUTHOR_TESTING=1 \
	  RELEASE_TESTING=1 \
	  AUTOMATED_TESTING=1

check: $(GSOURCE_FILES) ## syntax check and create source from .in file

.PHONY: test-author
test-author::
	$(NO_ECHO)mkdir -p xt/author; \
	PERL5LIB= prove -I lib -I local/lib/perl5 -r xt/author

.PHONY: test-release
test-release::
	$(NO_ECHO)mkdir -p xt/release; \
	PERL5LIB= prove -I lib -I local/lib/perl5 -r xt/release

.PHONY: test-smoke
test-smoke::
	$(NO_ECHO)mkdir -p xt/smoke; \
	PERL5LIB= prove -I lib -I local/lib/perl5 -r xt/smoke

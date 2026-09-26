#-*- mode: makefile; -*-
#
# Bootstrap support for self-hosting CPAN::Maker::Bootstrapper.
#
# Phase 1:
#   Use the installed CMB to resolve the current source tree.
#
# Phase 2:
#   Re-run the normal build using the CMB being built by placing the
#   project bin/ and lib/ ahead of the installed versions.
#

BOOTSTRAP_GOALS := bootstrap bootstrap-resolve bootstrap-build

ifneq ($(filter $(BOOTSTRAP_GOALS),$(MAKECMDGOALS)),)
BOOTSTRAP_BUILD := 1
endif

BOOTSTRAP_PATH := $(CURDIR)/bin:$(PATH)
BOOTSTRAP_PERL5LIB := $(CURDIR)/lib:$(PERL5LIB)

.PHONY: bootstrap bootstrap-resolve bootstrap-build

bootstrap: bootstrap-resolve
	$(NO_ECHO)$(MAKE) \
	  PATH="$(BOOTSTRAP_PATH)" \
	  PERL5LIB="$(BOOTSTRAP_PERL5LIB)" \
	  SYNTAX_CHECKING=off \
	  LINT=off \
	  SCAN=off \
	  SKIP_TESTS=1 \
	  bootstrap-build

# This is the only phase that uses the installed CMB.
bootstrap-resolve:
	$(NO_ECHO)$(MAKE) \
	  SYNTAX_CHECKING=off \
	  LINT=off \
	  SCAN=off \
	  SKIP_TESTS=1 \
	  $(PERL_MODULES) $(BIN_FILES)

# At this point command -v cmb should resolve to ./bin/cmb and Perl should
# load CPAN::Maker::Bootstrapper modules from ./lib.
bootstrap-build:
	$(NO_ECHO)$(MAKE) \
	  SYNTAX_CHECKING=off \
	  LINT=off \
	  SCAN=off \
	  SKIP_TESTS=1 \
	  $(TARBALL)

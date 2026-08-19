#-*- mode: makefile; -*-

.PHONY: help

help: ## show this help message
	@tmp=$$(mktemp); \
	trap 'rm -f $$tmp' EXIT; \
	{ \
		echo ""; \
		echo "Usage: make [target] [VARIABLE=value]"; \
		echo ""; \
		echo "Targets:"; \
		grep -Eh '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) \
			| sort \
			| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'; \
		echo ""; \
		echo "Variables:"; \
		echo "  SCAN=OFF                  disable dependency scanning (default: ON)"; \
		echo "  LINT=OFF                  disable perlcritic, perltidy checking"; \
		echo "  SYNTAX_CHECKING=OFF       disable syntax checking"; \
		echo "  SKIP_TESTS=1              disable tests"; \
		echo "  POD=extract|remove        extract or strip POD from modules"; \
		echo "  STUB=path|cli             module stub template (default: class-module.pm.tmpl)"; \
		echo "  MODULE_NAME=Foo::Bar      override module name derivation"; \
		echo "  MIN_PERL_VERSION=n        minimum Perl version (default: 5.010)"; \
		echo "  ALIAS=script-name         name modulino wrapper (default: MODULE_NAME)"; \
		echo ""; \
	} > $$tmp; \
	pager="$${PAGER:-$$(command -v less || command -v more || echo cat)}"; \
	$$pager $$tmp

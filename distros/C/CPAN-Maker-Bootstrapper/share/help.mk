#-*- mode: makefile; -*-

.PHONY: help

help: ## show this help message
	@echo ""
	@echo "Usage: make [target] [VARIABLE=value]"
	@echo ""
	@echo "Targets:"
	@grep -Eh '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) \
	  | sort \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  SCAN=OFF                  disable dependency scanning (default: ON)"
	@echo "  POD=extract|remove        extract or strip POD from modules"
	@echo "  STUB=path|cli             module stub template (default: class-module.pm.tmpl)"
	@echo "  MODULE_NAME=A::B          override module name derivation"
	@echo "  MIN_PERL_VERSION=n        minimum Perl version (default: 5.010)"
	@echo "  MODULINO_NAME=module      module name for modulino wrapper (default: MODULE_NAME)"
	@echo "  ALIAS=script-name         name modulino wrapper (default: MODULE_NAME)"
	@echo "  LINT=OFF                  disable perlcritic, perltidy checking"
	@echo ""

MAINTAINER=Johnathan Kupferer <jtk@uic.edu>

.PHONY: help test clean install

help:
	@echo
	@echo "Basic application tests:"
	@echo "  make test"
	@echo
	@echo "Clean up build/test products:"
	@echo "  make clean"
	@echo
	@echo "Install (only works from a release directory):"
	@echo "  make install"
	@echo

Build: Build.PL
	perl Build.PL

test: Build
	./Build test

clean: Build
	./Build realclean

install: Build
	./Build installdeps
	./Build install

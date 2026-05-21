#-*- mode: makefile; -*-

.PHONY: version release minor major

version:
	@if [[ "$$bump" = "release" ]]; then \
	  bump=2; \
	elif [[ "$$bump" = "minor" ]]; then \
	  bump=1; \
	elif [[ "$$bump" = "major" ]]; then \
	  bump=0; \
	fi; \
	ver=$$(cat VERSION); \
	v=$$(echo $${bump}.$$ver | \
	  perl -a -F[.] -pe '$$i=shift @F;$$F[$$i]++;$$j=$$i+1;$$F[$$_]=0 for $$j..2;$$"=".";$$_="@F"'); \
	echo $$v >VERSION;
	@cat VERSION

release: ## bump the patch version (major.minor.patch)
	@$(MAKE) -s version bump=release

minor: ## bump the minor version (major.minor.patch)
	@$(MAKE) -s version bump=minor

major: ## bump the major version (major.minor.patch)
	@$(MAKE) -s version bump=major

#-*- mode: makefile; -*-

MANAGED_FILES = \
    git.mk \
    help.mk \
    version.mk \
    perl.mk \
    release-notes.mk

BOOTSTRAPPER_DIST_DIR := $(shell perl -MFile::ShareDir=dist_dir \
    -e 'print dist_dir(q{CPAN-Maker-Bootstrapper})' 2>/dev/null || true)

.PHONY: update

INCLUDES_DIR = .includes

.PHONY: post-update
post-update: 
	@mkdir -p $(INCLUDES_DIR); \
	for f in $(MANAGED_FILES); do \
	  src="$(BOOTSTRAPPER_DIST_DIR)/$$f"; \
	  test -e "$$src" || continue; \
	  cp "$$src" "$(INCLUDES_DIR)/$$f"; \
	  chmod -w "$(INCLUDES_DIR)/$$f"; \
	done; \
	echo "Files updated. Review changes with: git diff"

.PHONY: update  ## update managed project files from the installed bootstrapper
update:
	@if [[ -e builder ]]; then \
	  chmod +w builder; \
	  cp $(BOOTSTRAPPER_DIST_DIR)/builder builder; \
	  chmod 0555 builder; \
	fi; \
	chmod +w Makefile; \
	cp $(BOOTSTRAPPER_DIST_DIR)/Makefile.txt Makefile; \
	chmod +w .includes/*; \
	cp $(BOOTSTRAPPER_DIST_DIR)/update.mk .includes/; \
	cp $(BOOTSTRAPPER_DIST_DIR)/upgrade.mk .includes/; \
	$(MAKE) post-update; \
	chmod -w Makefile .includes/*

.PHONY: update-available
update-available:
	@if [[ -n "$(BOOTSTRAPPER_VERSION)" && "$(PROJECT_NAME)" != "CPAN-Maker-Bootstrapper" ]]; then \
	  dist=$$(cpanm --info -l /dev/null 2>/dev/null CPAN::Maker::Bootstrapper || true); \
	  if [[ "$$dist" =~ -([0-9.]+)\.tar\.gz$$ ]]; then \
	    version="$${BASH_REMATCH[1]}"; \
	    update_available=$$(current="$(BOOTSTRAPPER_VERSION)" cpan="$$version" perl -Mversion -e 'print version->parse($$ENV{cpan}) > version->parse($$ENV{current});'); \
	    if [[ -z "$$update_available" ]]; then \
	      echo "CPAN::Maker::Bootstrapper $$version is up-to-date."; \
	    else \
	      echo "CPAN::Maker::Bootstrapper $$version available!"; \
	    fi; \
	  fi; \
	fi

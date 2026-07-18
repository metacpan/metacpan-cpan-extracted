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
	$(NO_ECHO)mkdir -p $(INCLUDES_DIR); \
	for f in $(MANAGED_FILES); do \
	  src="$(BOOTSTRAPPER_DIST_DIR)/$$f"; \
	  test -e "$$src" || continue; \
	  cp "$$src" "$(INCLUDES_DIR)/$$f"; \
	  chmod -w "$(INCLUDES_DIR)/$$f"; \
	done; \
	echo "Files updated. Review changes with: git diff"

.PHONY: update  ## update managed project files from the installed bootstrapper
update:
	$(NO_ECHO)if [[ -e builder ]]; then \
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
	$(NO_ECHO)if [[ -n "$(BOOTSTRAPPER_VERSION)" && "$(PROJECT_NAME)" != "CPAN-Maker-Bootstrapper" ]]; then \
	  if [[ "$(CMB_UPDATE_CHECK)" = "on" ]]; then \
	    dist=$$(cpanm --info -l /dev/null 2>/dev/null CPAN::Maker::Bootstrapper || true); \
	    if [[ "$$dist" =~ -([0-9.]+)\.tar\.gz$$ ]]; then \
	      cpan_version="$${BASH_REMATCH[1]}"; \
	      update_available=$$(current="$(BOOTSTRAPPER_VERSION)" cpan="$$cpan_version" perl -Mversion -e 'print version->parse($$ENV{cpan}) > version->parse($$ENV{current});'); \
	      if [[ -n "$$update_available" ]]; then \
	        echo "WARNING: CPAN::Maker::Bootstrapper $$cpan_version available! Run 'make upgrade'"; \
	      else \
	        echo "CPAN::Maker::Bootstrapper $(BOOTSTRAPPER_VERSION) is up-to-date with published version ($$cpan_version)."; \
	      fi; \
	    fi; \
	  else \
	    echo "CPAN::Maker::Bootstrapper update check skipped (CMB_UPDATE_CHECK=$(CMB_UPDATE_CHECK))."; \
	  fi; \
	  if [[ "$(CMB_VERSION_DRIFT)" != "ignore" ]]; then \
	    cmb_md5sums="$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{cmb_md5sums.txt});')"; \
	    if md5sum --status --check "$$cmb_md5sums" 2>/dev/null; then \
	      echo "CPAN::Maker::Bootstrapper (local) is up-to-date with the installed version."; \
	    elif [[ "$(CMB_VERSION_DRIFT)" = "warn" ]]; then \
	      echo "WARNING: CPAN::Maker::Bootstrapper (local) has drifted from the installed version. Run 'make update'"; \
	    else \
	      echo "ERROR: CPAN::Maker::Bootstrapper (local) has drifted from the installed version. Run 'make update', or set CMB_VERSION_DRIFT=warn (or =ignore) in config.mk to downgrade this check." >&2; \
	      exit 1; \
	    fi; \
	  else \
	    echo "CPAN::Maker::Bootstrapper drift check skipped (CMB_VERSION_DRIFT=ignore)."; \
	  fi; \
	fi

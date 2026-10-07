#-*- mode: makefile; -*-


INCLUDES_DIR = .includes/

MANAGED_MK_FILES = \
    bash-completion.mk \
    bootstrap.mk \
    builder.mk \
    git.mk \
    help.mk \
    local.mk \
    modulino.mk \
    perl.mk \
    publish.mk \
    release-notes.mk \
    test.mk \
    update.mk \
    upgrade.mk \
    version.mk

MANAGED_SOURCE_FILES = \
   Makefile.txt \
   builder \
   builder.env \
   gitignore

INCLUDES_FILES = $(addprefix $(INCLUDES_DIR),$(MANAGED_MK_FILES))

MANIFEST: $(INCLUDES_FILES) $(MANAGED_SOURCE_FILES)
	$(NO_ECHO)printf "%s\n" $(MANAGED_MK_FILES) $(MANAGED_SOURCE_FILES) | sort > $@

BOOTSTRAPPER_DIST_DIR := $(shell perl -MFile::ShareDir=dist_dir \
    -e 'print dist_dir(q{CPAN-Maker-Bootstrapper})' 2>/dev/null || true)

.PHONY: post-update
post-update: 
	$(NO_ECHO)mkdir -p $(INCLUDES_DIR); \
	for f in $(MANAGED_MK_FILES); do \
	  src="$(BOOTSTRAPPER_DIST_DIR)/$$f"; \
	  if [[ ! -e "$$src" ]]; then \
	    echo "ERROR: managed file not found: $$src" >&2; \
	    exit 1; \
	  fi; \
	  cp "$$src" "$(INCLUDES_DIR)$$f"; \
	  chmod -w "$(INCLUDES_DIR)$$f"; \
	done;	if [[ -e .gitignore ]]; then \
	  our_ignore="$$(mktemp)"; sort "$(BOOTSTRAPPER_DIST_DIR)/gitignore" > $$our_ignore; \
	  their_ignore="$$(mktemp)"; sort .gitignore > $$their_ignore; \
	  trap 'rm -r $$our_ignore $$their_ignore' EXIT; \
	  echo "updating .gitignore..."; \
	  comm -13 $$their_ignore $$our_ignore | tee -a .gitignore; \
	fi; \
	echo "Files updated. Review changes with: git diff"

.PHONY: update  ## update managed project files from the installed bootstrapper
update:
	$(NO_ECHO)if [[ -e builder ]]; then \
	  chmod +w builder; \
	  cp $(BOOTSTRAPPER_DIST_DIR)/builder builder; \
	  chmod 0555 builder; \
	fi; \
	chmod +w .includes/*; \
	cp $(BOOTSTRAPPER_DIST_DIR)/update.mk .includes/; \
	cp $(BOOTSTRAPPER_DIST_DIR)/upgrade.mk .includes/; \
	$(MAKE) post-update; \
	chmod +w Makefile; \
	cp $(BOOTSTRAPPER_DIST_DIR)/Makefile.txt Makefile; \
	chmod -w Makefile .includes/*

.PHONY: update-available
update-available:
	$(NO_ECHO)if [[ -n "$(BOOTSTRAPPER_VERSION)" && "$(PROJECT_NAME)" != "CPAN-Maker-Bootstrapper" ]]; then \
	  case "$(cmb_update_check)" in \
	    on) \
	      dist=$$(cpanm --info -l /dev/null 2>/dev/null CPAN::Maker::Bootstrapper || true); \
	      if [[ "$$dist" =~ -([0-9.]+)\.tar\.gz$$ ]]; then \
	        cpan_version="$${BASH_REMATCH[1]}"; \
	        update_available=$$(current="$(BOOTSTRAPPER_VERSION)" cpan="$$cpan_version" \
	          perl -Mversion -e 'print version->parse($$ENV{cpan}) > version->parse($$ENV{current});'); \
	        if [[ -n "$$update_available" ]]; then \
	          echo "WARNING: CPAN::Maker::Bootstrapper $$cpan_version available! Run 'make upgrade'"; \
	        else \
	          echo "CPAN::Maker::Bootstrapper $(BOOTSTRAPPER_VERSION) is up-to-date with published version ($$cpan_version)."; \
	        fi; \
	      fi; \
	      ;; \
	    off) \
	      echo "CPAN::Maker::Bootstrapper update check skipped (CMB_UPDATE_CHECK=$(CMB_UPDATE_CHECK))."; \
	      ;; \
	    *) \
	      echo "ERROR: invalid CMB_UPDATE_CHECK=$(CMB_UPDATE_CHECK); expected ON or OFF" >&2; \
	      exit 1; \
	      ;; \
	  esac; \
	  case "$(cmb_version_drift)" in \
	    ignore) \
	      echo "CPAN::Maker::Bootstrapper drift check skipped (CMB_VERSION_DRIFT=$(CMB_VERSION_DRIFT))."; \
	      ;; \
	    fail|warn) \
	      cmb_md5sums="$$(perl -MFile::ShareDir=dist_file \
	        -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{cmb_md5sums.txt});')"; \
	      if md5sum --status --check "$$cmb_md5sums" 2>/dev/null; then \
	        echo "CPAN::Maker::Bootstrapper (local) is up-to-date with the installed version."; \
	      elif [[ "$(cmb_version_drift)" = "warn" ]]; then \
	        echo "WARNING: CPAN::Maker::Bootstrapper (local) has drifted from the installed version. Run 'make update'"; \
	      else \
	        echo "ERROR: CPAN::Maker::Bootstrapper (local) has drifted from the installed version. Run 'make update', or set CMB_VERSION_DRIFT=WARN (or IGNORE) in config.mk to downgrade this check." >&2; \
	        exit 1; \
	      fi; \
	      ;; \
	    *) \
	      echo "ERROR: invalid CMB_VERSION_DRIFT=$(CMB_VERSION_DRIFT); expected FAIL, WARN, or IGNORE" >&2; \
	      exit 1; \
	      ;; \
	  esac; \
	fi

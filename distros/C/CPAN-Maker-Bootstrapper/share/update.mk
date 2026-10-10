#-*- mode: makefile; -*-

MANAGED_SOURCE_FILES = \
   Makefile.txt \
   builder \
   builder.env \
   gitignore

MANIFEST: $(INCLUDES_FILES) $(MANAGED_SOURCE_FILES)
	$(NO_ECHO)printf "%s\n" $(MANAGED_MK_FILES) $(MANAGED_SOURCE_FILES) | sort > $@

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
	     update_available="$$($(BOOTSTRAPPER) update-available)"; \
	     if [[ -n "$$update_available" ]]; then \
	        echo "WARNING: CPAN::Maker::Bootstrapper $$update_available available! Run 'make upgrade'"; \
	     else \
	        echo "CPAN::Maker::Bootstrapper $(BOOTSTRAPPER_VERSION) is up-to-date with published version."; \
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
	      cmb_md5sums="$$($(BOOTSTRAPPER) --path-only dist-file cmb_md5sums.txt)"; \
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

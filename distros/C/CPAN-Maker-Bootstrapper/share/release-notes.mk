.PHONY: release-notes
release-notes: ## creates release-notes/release-notes-{version}.md
	$(NO_ECHO)if [[ -n "$$DRYRUN" ]]; then \
	  DRYRUN='--dryrun'; \
	fi; \
	cmb release-notes $$DRYRUN

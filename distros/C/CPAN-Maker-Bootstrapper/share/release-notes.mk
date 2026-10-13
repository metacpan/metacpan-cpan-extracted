.PHONY: release-notes
release-notes: ## creates release-notes/release-notes-{version}.md
	$(NO_ECHO)if [[ -n "$$DRYRUN" ]]; then \
	  DRYRUN='--dryrun'; \
	fi; \
	if [[ -n "$$MODEL" ]]; then \
	  model="--model $$MODEL"; \
	fi; \
	cmb release-notes $$model $$DRYRUN

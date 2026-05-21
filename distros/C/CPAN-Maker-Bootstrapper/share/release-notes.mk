.PHONY: release-notes

release-notes: ## creates release-{version}.diffs, release-{version}.lst and release-{version}.tar.gz used for automatic release note generation
	@curr_ver=$(VERSION); \
	if [[ -n "$$LAST_TAG" ]]; then \
	  last_tag=$$LAST_TAG; \
	else \
	  last_tag=$$(git tag -l '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n 1); \
	fi; \
	diffs="release-$$curr_ver.diffs"; \
	diff_list="release-$$curr_ver.lst"; \
	diff_tarball="release-$$curr_ver.tar.gz"; \
	echo "Comparing $$last_tag to current $$curr_ver..."; \
	git diff --staged --no-ext-diff "$$last_tag"  > "$$diffs"; \
	git diff --staged --name-only --diff-filter=AMR "$$last_tag"  > "$$diff_list"; \
	tar -cf - --transform "s|^|release-$$curr_ver/|" -T "$$diff_list" | gzip > "$$diff_tarball"; \
	ls -alrt release-$${curr_ver}*.*

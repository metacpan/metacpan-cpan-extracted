#-*- mode: makefile; -*-

PERL_MODULES_IN = $(PERL_MODULES:.pm=.pm.in)
BIN_FILES_IN = $(BIN_FILES:=.in)

RECOMMENDED_ARTIFACTS = \
     Makefile \
     $(PERL_MODULES_IN) \
     $(BIN_FILES_IN) \
     $(TESTS) \
     ChangeLog \
     buildspec.yml \
     VERSION \
     README.md \
     requires \
     test-requires \
     .gitignore \
     .includes/ \
     .prompts/

.PHONY: git
git: ## initializes a git repository and commits the recommended artifacts
	$(MAKE) clean
	git init -b main; \
	date +'%a %b %d %H:%M:%S  $(GIT_NAME)  $(GIT_EMAIL)' >ChangeLog
	echo -e "\n\t[1.0.0]:\n" >>ChangeLog
	for f in $(RECOMMENDED_ARTIFACTS); do \
	  if test -e "$$f" || test -d "$$f"; then \
	    git add "$$f"; \
	  fi; \
	done; \
	changelog_files=$$(mktemp); trap 'rm -f $$changelog_files' EXIT; \
	for a in $$(find . -type d -path "./.git" -prune -o -type f -print); do \
	  echo -e "\t* $${a#./}: new" >>$$changelog_files; \
	done; \
	sort $$changelog_files >>ChangeLog; \
	git add ChangeLog; \
	git commit -m 'BigBang'


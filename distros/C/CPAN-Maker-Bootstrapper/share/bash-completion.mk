#-*- mode: makefile; -*-

ALIAS ?= $(shell echo $(MODULE_NAME) | sed -e 's/::/-/g' | tr [:upper:] [:lower:])

MODULINO = bin/$(ALIAS)

$(MODULINO): $(MODULE_PATH)
	$(NO_ECHO)if ! [[ -f $(MODULINO).in ]]; then \
	  $(MAKE) modulino ALIAS=$(ALIAS); \
	fi
	$(NO_ECHO)cp $(MODULINO).in $@; \
	chmod +x $@

COMPLETION_PATH = ~/.local/share/bash-completion/completions/$(ALIAS)

$(COMPLETION_PATH): $(MODULINO)
	$(NO_ECHO)$(MODULINO) -generate-completion >$@ 2>/dev/null || \
	echo "ERROR: only sub-classes of CLI::Simple can -generate-completion"

.PHONY: bash-completion
bash-completion: $(COMPLETION_PATH) ## create a bash completion function for CLI::Simple scripts
	$(NO_ECHO)echo "source $(COMPLETION_PATH)"


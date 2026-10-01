.PHONY: publish
publish: $(TARBALL) ## publish a distribution to CPAN (make publish PAUSE_USER= PAUSE_PASSWORD=)
	$(NO_ECHO)tarball=$$(realpath $(TARBALL)); \
	workdir=$$(mktemp -d); trap 'rm -rf "$$workdir"' EXIT; \
	tar xfz "$$tarball" -C "$$workdir"; \
	cd "$$workdir"/*; \
	perl Makefile.PL; \
	make; \
	make test; \
	if [[ -z "$(PAUSE_USER)" ]] || [[ -z "$(PAUSE_PASSWORD)" ]]; then \
	  echo "ERROR: set PAUSE_USER and PAUSE_PASSWORD"; \
	  exit 1; \
	fi; \
	PAUSE_USER=$(PAUSE_USER) PAUSE_PASSWORD=$(PAUSE_PASSWORD) $(BOOTSTRAPPER) publish-to-cpan $$tarball

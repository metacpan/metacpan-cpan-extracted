# -*- mode: sh; -*-

export PAUSE_USER
export PAUSE_PASSWORD

.PHONY: publish
publish: $(TARBALL) pre-publish ## publish a distribution to CPAN (make publish PAUSE_USER= PAUSE_PASSWORD=)
	$(NO_ECHO)if [[ -z "$$PAUSE_USER" ]] || [[ -z "$$PAUSE_PASSWORD" ]]; then \
	  echo "ERROR: set PAUSE_USER and PAUSE_PASSWORD"; \
	  exit 1; \
	fi; \
	tarball=$$(realpath $(TARBALL)); \
	workdir=$$(mktemp -d); trap 'rm -rf "$$workdir"' EXIT; \
	tar xfz "$$tarball" -C "$$workdir"; \
	cd "$$workdir"/*; \
	perl Makefile.PL; \
	make test; \
	$(BOOTSTRAPPER) publish-to-cpan $$tarball
	$(MAKE) post-publish

pre-publish::

post-publish::

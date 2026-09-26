test-requires.cpanfile: test-requires
	$(NO_ECHO)$(CPAN_MAKER) create-cpanfile --dependency-type requires $< -o $@

local: local/.installed

local/.installed:  cpanfile.runtime test-requires.cpanfile
	$(NO_ECHO)if [[ -z "$(CPAN_INSTALLER)" ]]; then \
	  mkdir -p local/lib/perl5; \
	else \
	  case "$$(basename $(CPAN_INSTALLER))" in \
	    cpm) \
	      resolvers=(); \
	      for a in $$(cat build-mirrors 2>/dev/null); do \
	        resolvers+=(--resolver 02packages,$$a); \
	      done; \
	      cpm install -L local --cpanfile $< "$${resolvers[@]}" --show-build-log-on-failure; \
	      cpm install -L local --cpanfile test-requires.cpanfile "$${resolvers[@]}" --show-build-log-on-failure;; \
	    carton) \
	      mirror=$$(head -1 build-mirrors 2>/dev/null); \
	      env PERL_CARTON_MIRROR="$$mirror" carton install ;; \
	    *) echo >&2 "ERROR: unsupported CPAN_INSTALLER: $(CPAN_INSTALLER)"; exit 1 ;; \
	  esac; \
	fi; \
	touch $@

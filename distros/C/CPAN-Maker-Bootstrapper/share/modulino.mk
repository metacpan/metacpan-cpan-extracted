#-*- mode: makefile; -*-

modulino.tmpl:
	$(NO_ECHO)modulino_path=$$(perl -MFile::ShareDir=dist_file -e 'print dist_file(q{CPAN-Maker-Bootstrapper}, q{modulino.tmpl});' 2>/dev/null); \
	cp $$modulino_path $@

.PHONY: modulino
modulino: modulino.tmpl ## creates a bash script that calls your modulino (MODULE_NAME=module ALIAS=name)
	$(NO_ECHO)trap 'rm -f modulino.tmpl' EXIT; \
	MODULE_NAME="$(MODULE_NAME)"; \
	ALIAS="$${ALIAS:-$$MODULE_NAME}"; \
	binfile=$$(echo "$$ALIAS" | perl -npe 's/::/\-/g;'); \
	modulino="bin/$${binfile,,}"; \
	sed -e "s/[@]MODULE_NAME[@]/$$MODULE_NAME/" \
	    -e "s/[@]ALIAS[@]/$$ALIAS/" $< > "$${modulino}.in"; \
	test -e .gitignore && { grep -q "$$modulino" .gitignore || echo "$$modulino" >> .gitignore; }; \
	echo "$$modulino"

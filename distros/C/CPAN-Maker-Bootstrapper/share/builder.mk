#-*- mode: makefile; -*-

.PHONY: workflow
workflow: ## install the GitHub Actions workflow
	$(NO_ECHO)
	pwd=$$(pwd); \
	$(BOOTSTRAPPER) dist-file CPAN-Maker-Bootstrapper builder $$pwd; \
	chmod +x $$pwd/builder; \
	build_requires="$$(mktemp)"; trap 'rm -f $$build_requires' EXIT; \
	test -e build-requires || touch build-requires; \
	cp build-requires $$build_requires; \
	$(BOOTSTRAPPER) dist-file CPAN-Maker-Bootstrapper build-requires >>$$build_requires; \
	sort -u $$build_requires > build-requires; \
	mkdir -p $$pwd/.github/workflows; \
	project_name="$(PROJECT_NAME)"; \
	project_name="$${project_name,,}"; \
	$(BOOTSTRAPPER) dist-file CPAN-Maker-Bootstrapper build.yml | \
	  sed -e 's/CPAN::Maker::Bootstrapper/$(PROJECT_NAME)/' \
	      -e "s/cpan-maker-bootstrapper/$$project_name/" > $$pwd/.github/workflows/build.yml; \
	echo "** Installed build-requires, builder, .github/workflows/build.yml"; \
	echo "** Add to your repo:"; \
	echo "git add build-requires builder .github/workflows/build.yml"

DOCKER_BUILD_IMAGE    ?= debian:trixie
BUILDER               ?= builder
BUILD_LOG             ?= $(shell echo "build-$$(date +'%Y%m%d%H%M%S').log")
DOCKER_CPAN_INSTALLER ?= cpm

.PHONY: build-ci
build-ci: ## build your project in a clean-room environment
	@test -n "$(DOCKER)" || (echo "docker unavailable: install docker or set DOCKER" && exit 1); \
	test -x "$$(pwd)/$(BUILDER)" || (echo "no builder. set BUILDER or run make workflow to install builder" && exit 1); \
	start_time=$$(date +%s); \
	$(DOCKER) run --rm \
	  -v "$$(pwd):/src:ro" \
	  -e INSTALLER="$(DOCKER_CPAN_INSTALLER)" \
	  -e MODULE_NAME="$(MODULE_NAME)" \
	  -e CMB_VERSION_DRIFT=ignore \
	  $(DOCKER_BUILD_IMAGE) \
	  bash -c 'cp -a /src /build && /build/$(BUILDER) /build' \
	  2>&1 | tee "$(BUILD_LOG)"; \
	end_time=$$(date +%s); \
	total_time=$$(($$end_time - $$start_time)); \
	echo "Build time: $$(date -u -d @$$total_time +%T)" >> "$(BUILD_LOG)"; \
	ln -sf "$(BUILD_LOG)" build.log; \
	echo "See build.log"

builder-pre::

builder-post::

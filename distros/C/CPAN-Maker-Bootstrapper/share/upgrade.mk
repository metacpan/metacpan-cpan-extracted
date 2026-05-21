#-*- mode: makefile; -*-

BOOTSTRAPPER_VERSION := $(shell perl -MCPAN::Maker::Bootstrapper \
    -e 'print $$CPAN::Maker::Bootstrapper::VERSION' 2>/dev/null)

CPANM := $(shell command -v cpanm)

define get_metacpan_version =
  use JSON::PP;

  my $url  = 'https://fastapi.metacpan.org/v1/release/CPAN-Maker-Bootstrapper';
  my $json = join q{}, `curl -sf $url`;

  exit 1 if !$json;

  my $data = JSON::PP::decode_json($json);

  print $data->{version};
endef

export s_get_metacpan_version = $(value get_metacpan_version)

define check_upgrade =
  current="$(BOOTSTRAPPER_VERSION)"; \
  latest=$$(perl -e "$$s_get_metacpan_version"); \
  if [[ -z "$$latest" ]]; then \
    echo "WARNING: could not retrieve version from MetaCPAN"; \
    exit 1; \
  fi; \
  if [[ "$$current" = "$$latest" ]]; then \
    echo "Already at latest version ($$current)"; \
    needs_upgrade=0; \
  else \
    echo "Version $$latest is available (you have $$current)"; \
    needs_upgrade=1; \
  fi
endef

.PHONY: check-upgrade upgrade-check upgrade cpanm

check-upgrade upgrade-check: ## check MetaCPAN for a newer version of CPAN::Maker::Bootstrapper
	@$(check_upgrade)

upgrade: ## upgrade CPAN::Maker::Bootstrapper and update managed project files
	@$(check_upgrade); \
	if [[ "$$needs_upgrade" -eq 0 ]]; then \
	  exit 0; \
	fi; \
	if [[ -z "$(CPANM)" ]]; then \
	  echo "WARNING: cpanm not found - install with:"; \
	  echo "  make cpanm"; \
	  exit 1; \
	fi; \
	echo "Upgrading..."; \
	$(CPANM) CPAN::Maker::Bootstrapper && $(MAKE) update

cpanm: ## install cpanminus if not already installed
	curl -L https://cpanmin.us | perl - App::cpanminus

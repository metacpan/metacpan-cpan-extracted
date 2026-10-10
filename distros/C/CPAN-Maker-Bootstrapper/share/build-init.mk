#-*- mode: makefile; -*-

CPAN_INSTALLER ?= $(firstword $(CPM) $(CARTON))

ifeq ($(CPAN_INSTALLER),)
  $(warning no cpm/carton found -- set SYNTAX_CHECKING=off if builds fail to find dependencies)
endif

ifeq ($(MD_UTILS),)
    $(warning Markdown::Render is not installed - run: cpanm Markdown::Render to generate .md files from pod)
endif

ifeq ($(SCANDEPS),)
  SCAN = OFF
else
  SCAN ?= ON
endif

scan_on := $(filter on,$(call lc,$(SCAN)))

ifeq ($(BOOTSTRAPPER),)
  $(error CPAN::Maker::Bootstrapper not installed - run cpanm CPAN::Maker::Bootstrapper)
endif

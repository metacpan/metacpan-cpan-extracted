% my $p = shift;
#  Copyright (C) <%= $p->{year} %> <%= $p->{fullName} %>

AUTOMAKE_OPTIONS =  foreign


SUBDIRS = thirdparty lib etc frontend

BIN = bin/$(MJ_SCRIPT).pl

PUB := $(shell find public -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -type f -print )

TEMPL := $(shell test -d templates && find templates -type f -name "*.ep")
SHARE := $(shell test -d share && find share -type f -name "*.po") $(SHARE)

PERLTESTS := $(shell find t -name "*.t")

THIRDPARTY_DIR := $(shell pwd)/thirdparty

EXTRA_DIST = VERSION PERL_MODULES COPYRIGHT LICENSE CHANGES AUTHORS bootstrap $(PUB) \
	$(wildcard t/*.t) $(BIN) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE)


YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)

datadir = $(prefix)
nobase_data_DATA = $(PUB) $(TEMPL) $(SHARE)

dist_bin_SCRIPTS = $(BIN)

all-local:
	$(GMAKE) public/script/$(QX_CLASS).js

README COPYRIGHT: VERSION
	$(PERL) -i -p -e 's/(#VERSION#|\d+\.\d+\.\d+[^.\s]*)/$(PACKAGE_VERSION)/g;s/(#YEAR#|20[1-4]\d)/$(YEAR)/g;s/(#DATE#|20[1-9]\d-[01]\d-[0-3]\d)/$(DATE)/g;' $@

dist-hook:
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;' $(distdir)/public/index.html $(distdir)/public/script/$(QX_CLASS).js
	$(PERL) -i -p -e 's/\$$VERSION\s*=\s*".+?";/\$$VERSION = "$(PACKAGE_VERSION)";/;'  $(distdir)/lib/$(MJ_CLASS).pm

install-exec-hook:
	[ "$(PERL5LIB)" == "" ] || cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# PERL5LIB}{use lib qw($(PERL5LIB)); # PERL5LIB}' $(BIN) || true
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# LIBDIR}{use lib qw($(libdir)); # LIBDIR}' $(BIN)
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{^#!.*perl.*}{#!$(PERL)};' $(BIN)
	[ ! -d $(THIRDPARTY_DIR)/lib/perl5 ] || cp -fr $(THIRDPARTY_DIR)/lib/perl5/* $(DESTDIR)$(libdir)


test:
	$(PERL) "-MExtUtils::Command::MM" "-e" "test_harness(0, 'lib','thirdparty/lib/perl5')" t/*.t


if BUILD_QOOXDOO_APP

CALLBACKERY_PATH := $(shell PERL5LIB=lib:$(PERL5LIB):thirdparty/lib/perl5 $(PERL) -e 'use File::Basename;use Cwd qw(realpath); eval { require CallBackery }; print !$$@ ? realpath(dirname($$INC{q{CallBackery/Config.pm}}).q{/qooxdoo}) : "CALLBACKERY_NOT_FOUND" ' )

public/script/$(QX_CLASS).js: $(shell find frontend/source $(CALLBACKERY_PATH) -type f ) frontend/config.json config.status
	cd frontend && $(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CALLBACKERY_PATH:$(CALLBACKERY_PATH) -m CACHE:./cache -m BUILD_PATH:../public build

endif

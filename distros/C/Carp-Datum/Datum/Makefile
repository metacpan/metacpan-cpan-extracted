# -*- Mode: Makefile -*-
#
# $Id: Makefile,v 0.1 2001/03/31 10:04:36 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Makefile,v $
# Revision 0.1  2001/03/31 10:04:36  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

BYACC = pbyacc
BYACC_P = Parser
BYACC_OPT = -P $(BYACC_P)
BYACC_FILE = ./Parser.y
BYACC_TARGET = ./$(BYACC_P).pm

RM = /bin/rm

$(BYACC_TARGET): $(BYACC_FILE)
	@if test -e $(BYACC_TARGET) -a ! -w $(BYACC_TARGET); then \
		@echo "$(BYACC_TARGET) is not writable"; \
	else echo "$(BYACC) $(BYACC_OPT) $(BYACC_FILE)"; \
		$(BYACC) $(BYACC_OPT) $(BYACC_FILE) && \
		perl -pi \
			-e 's/[^\\](\$$\$$1)/\\$$1/g;' \
			-e 's/\$$\$$1/\$$\\\$$1/g' $(BYACC_TARGET); \
	fi;

clean::
	$(RM) -f $(BYACC_TARGET)


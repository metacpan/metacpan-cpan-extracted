#!/bin/sh
# $Id: coverage.sh,v 1.1 2008/02/26 21:54:55 drhyde Exp $

cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover make test
cover

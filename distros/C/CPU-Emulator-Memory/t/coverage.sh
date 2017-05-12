#!/bin/sh
# $Id: coverage.sh,v 1.1 2008/02/28 20:40:13 drhyde Exp $

cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover make test
cover

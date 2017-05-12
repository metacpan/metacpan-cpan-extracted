#!/bin/sh

cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover=-coverage,statement,branch,condition,path,subroutine make test
cover

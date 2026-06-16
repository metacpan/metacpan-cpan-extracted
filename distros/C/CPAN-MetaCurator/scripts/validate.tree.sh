#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/

cp /dev/null log/development.log

# On the command line:
# INCLUDE_PACKAGES=1
# export INCLUDE_PACKAGES
# echo $INCLUDE_PACKAGES
# scripts/export.tree.sh

time scripts/validate.tree.pl -include_packages $INCLUDE_PACKAGES

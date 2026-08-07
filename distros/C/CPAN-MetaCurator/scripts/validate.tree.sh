#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/

scripts/zap.log.sh

cp ~/backup/02packages.details.txt /tmp
cp ~/perl.modules/CPAN-MetaPackager/data/cpan.metapackager.sqlite /tmp

INCLUDE_PACKAGES=1
export INCLUDE_PACKAGES
echo INCLUDE_PACKAGES=$INCLUDE_PACKAGES

time scripts/validate.tree.pl -include_packages $INCLUDE_PACKAGES

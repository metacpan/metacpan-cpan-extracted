#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/

scripts/zap.log.sh
time scripts/export.tree.pl -log_level debug -include_packages $INCLUDE_PACKAGES

declare -x SOURCE=html/cpan.metacurator.tree.html
declare -x DEST=$DH/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST

declare -x DEST=~/savage.net.au/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST

#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/

cp /dev/null log/development.log

time scripts/export.tree.pl -include_packages $INCLUDE_PACKAGES

declare -x SOURCE=html/cpan.metacurator.tree.html
declare -x DEST=$DH/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST

declare -x DEST=~/savage.net.au/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST

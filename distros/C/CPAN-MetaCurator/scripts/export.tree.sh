#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaCurator/

scripts/export.tree.pl

declare -x SOURCE=html/cpan.metacurator.tree.html
declare -x DEST=$DH/misc

cp $SOURCE $DEST
echo Copied $SOURCE to $DEST

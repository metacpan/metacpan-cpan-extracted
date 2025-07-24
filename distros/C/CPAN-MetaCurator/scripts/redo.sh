#!/bin/bash

declare -x PREFIX=cpan.metacurator

mv ~/Downloads/tiddlers.json data/$PREFIX.tiddlers.json
cd $HOME/perl.modules/CPAN-MetaCurator/
echo Work dir: `pwd`
gss
cp /dev/null log/development.log
git commit -am"$1"
build.module.sh CPAN::MetaCurator 1.00

scripts/drop.tables.pl
scripts/create.tables.pl
scripts/populate.sqlite.tables.pl
scripts/export.as.tree.pl

declare -x SOURCE=html/$PREFIX.tree.html
declare -x DEST=$DS/misc

cp $SOURCE $DEST

echo Copied $SOURCE to $DEST
echo Lastly check no other tiddlers.json in ~/Downloads

declare -x FILE1='/home/ron/Downloads/tiddlers(1).json'

if [[ -a $FILE1 ]]
then
	echo Warning: $FILE1 exists
fi

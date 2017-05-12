#!/bin/sh

export PERL5LIB=".:$PERL5LIB"

cpanm -n --pp --installdeps . -L local || exit 1
cpanm -n --pp Docopt -L local || exit 1

cpanm -n --pp App::FatPacker::Simple -L perl5 || exit 1
perl -Mlocal::lib=perl5 perl5/bin/fatpack-simple script/mimi || exit 1

#!/bin/sh

export PERL5LIB=".:local/lib/perl5:$PERL5LIB"

cpanm -q -n --pp --installdeps . -L local

cpanm -q -n --pp App::FatPacker::Simple -L perl5
perl -Mlocal::lib=perl5 perl5/bin/fatpack-simple script/kritika

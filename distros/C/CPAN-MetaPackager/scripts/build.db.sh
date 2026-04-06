#!/bin/bash

cd $HOME/perl.modules/CPAN-MetaPackager

scripts/zap.log.sh
scripts/drop.tables.pl
scripts/create.tables.pl

time scripts/populate.sqlite.tables.pl

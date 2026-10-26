#!/bin/bash

scripts/zap.log.sh; scripts/parse.metacpan.recent.pl  -in /tmp/$1.html -out /tmp/$1.csv
scripts/zap.log.sh ; scripts/check.module.names.pl -names /tmp/$1.csv -log debug

#!/bin/bash

bu.perl.sh App-Office-Contacts

perl Makefile.PL

make

make install

make dist

mv App-Office-Contacts-2.03.tar.gz ~/savage.net.au/Perl-modules

gss

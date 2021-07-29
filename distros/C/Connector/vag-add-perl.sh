#!/bin/bash

perlbrew install-cpanm

latest=$(perlbrew available | perl -ne 'if ( m{\s(perl-5\.(6|8|[0-9]+[02468])\.[0-9]+)\s*$} ) {print "$1\n"; exit}')

if [ -z "$latest" ]; then
    echo "ERROR: Unable to determine latest stable perl from 'perlbrew available'" 1>&2
    exit 1
fi

perlbrew install $latest
perlbrew use $latest
cpanm Module::Install
cpanm --installdeps --notest /vagrant

perlbrew --notest install perl-5.10.1
perlbrew use perl-5.10.1

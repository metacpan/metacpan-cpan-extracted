#!/bin/sh

die () {
    msg="$1\n"
    shift
    printf "$msg" "$@" 1>&2
    exit 1
}

use=`
    for mod in \
        parent \
        Exporter \
        HTTP::Parser \
        HTTP::Tiny \
        Plack::App::Proxy \
        Plack::App::Proxy::Backend::HTTP::Tiny \
        Plack::Handler::Starlight \
        Plack::Handler::Thrall \
        Plack::Middleware::AccessLog \
        Plack::Middleware::Proxy::Requests \
        Plack::Middleware::Proxy::Connect::IO \
        Plack::Middleware::TrafficLog \
        Time::Local \
    ; do
        echo "--use=$mod"
    done
`

delete=`
    for mod in \
        Sub::Name \
        Time::TZOffset \
    ; do
        path=$(echo "$mod" | sed 's,::,/,g')
        printf "\,^$path\.pm$,d; "
    done
`

# cpanm --reinstall if parent Exporter HTTP::Tiny

cd `dirname $0`

rm -f fatpacker.trace packlists pureproxy
rm -rf fatlib

PLACK_HTTP_PARSER_PP=1 fatpack trace $use ../script/pureproxy.pl

sed -i "$delete" fatpacker.trace

fatpack packlists-for `cat fatpacker.trace` >packlists

fatpack tree `cat packlists`

for mod in \
    if \
    parent \
    Exporter \
    HTTP::Tiny \
    Time::Local \
; do
    path=$(echo "$mod" | sed 's,::,/,g')
    if [ ! -f fatlib/$path.pm ]; then
        mkdir -p fatlib/$(dirname $path)
        cp -f $(perl -le "use $mod (); print \$INC{'$path.pm'}") fatlib/$path.pm  # "
        test -f fatlib/$path.pm || die "Missing module at site_perl. Reinstall it with command:\ncpanm --reinstall %s" $mod
    fi
done

rm -rf fatlib/auto/share

fatpack file ../script/pureproxy.pl > pureproxy

sed -i 's,^#!.*/perl$,#!/usr/bin/env perl,' pureproxy
chmod +x pureproxy

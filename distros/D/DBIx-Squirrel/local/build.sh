# vi: syntax=bash:ts=4:sw=4:et
#!/usr/bin/env bash

VERSION=$(cat dist.ini | grep -w version | cut -d' ' -f3)
MINOR_VERSION=$(echo $VERSION | cut -d'.' -f2)
DEVELOPER_RELEASE=$((($MINOR_VERSION % 2 != 0)))
NAME="DBIx-Squirrel"
ARTEFACT="${NAME}-${VERSION}.tar.gz"
FOLDER="${NAME}-${VERSION}"

dzil clean &&
dzil build || exit $?
dzil cover --outputdir ../cover_db

sleep 1

cp "${FOLDER}/cpanfile" ./
cp "${FOLDER}/Makefile.PL" ./
pod2markdown lib/DBIx/Squirrel.pod >docs/POD/README.md

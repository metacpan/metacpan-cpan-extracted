# vi: syntax=bash:ts=4:sw=4:et
#!/usr/bin/env bash

VERSION=$(cat dist.ini | grep -w version | cut -d' ' -f3)
MINOR_VERSION=$(echo $VERSION | cut -d'.' -f2)
DEVELOPER_RELEASE=$((($MINOR_VERSION % 2 != 0)))
NAME="DBIx-Squirrel"
ARTEFACT="${NAME}-${VERSION}.tar.gz"
FOLDER="${NAME}-${VERSION}"

cd "${FOLDER}"
for PREREQ in $(
    cat MYMETA.json |
    jq -r '.prereqs.test.requires, .prereqs.runtime.requires | keys []' | 
    grep -v -E '^perl|lib|open|strict|warnings|List::Util$'
); do
    cpanm $PREREQ || cpanm --force $PREREQ
done
perl Makefile.PL &&
make &&
make test
cd -

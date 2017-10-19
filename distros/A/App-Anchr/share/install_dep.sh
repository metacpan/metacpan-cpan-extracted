#!/usr/bin/env bash

check_install () {
    if brew list --versions $1 > /dev/null; then
        echo "$1 already installed"
    else
        brew install $1;
    fi
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    check_install jdk
    check_install wang-q/tap/superreads
fi

for package in graphviz jq parallel pigz;
do
    check_install ${package}
done

for package in bbtools fastqc jellyfish minimap miniasm poa samtools seqtk sickle;
do
    check_install homebrew/science/${package};
done

for package in faops jrange jrunlist reaper scythe sparsemem dazz_db@20161112 daligner@20170203 quorum@1.1.1;
do
    check_install wang-q/tap/${package};
done

exit 0

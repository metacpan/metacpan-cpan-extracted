#!/bin/bash

set -E
trap "stop_build_and_install" ERR

deps_path=$(dirname $0)
arcus_c_client="arcus-c-client-1.14.0"
zookeeper="arcus-zookeeper-3.5.9-p3"

## Error handling
stop_build_and_install() {
    echo -e "\nError has occurred. $0 has failed"
    echo "Check $deps_path/install.log"
    exit -1
}

## Build and install function
##
## @param $1 dependency name
## @param $2 configure options
build_and_install() {
    ## If the source directory of dependency already exists, remove it.
    if test -d $deps_path/$1 ; then
        rm -rf $deps_path/$1
    fi
    if [[ "$prefix" =~ "--prefix=$deps_path/$1" ]]; then
        echo "ERROR: Can't install to the same path which exists source files. ($deps_path/$1)" | tee $deps_path/install.log
        exit 1
    fi

    tar -xzf $deps_path/$1.tar.gz -C $deps_path/ >> $deps_path/install.log 2>&1
    pushd $deps_path/$1 > /dev/null
    echo -n "[$1 installation] .. START"
    echo -e "\n## LOG_RECORD [$1]\n" >> $deps_path/install.log
    ./configure $2 >> $deps_path/install.log 2>&1
    make >> $deps_path/install.log 2>&1
    make install >> $deps_path/install.log 2>&1
    rm -rf $deps_path/$1 > /dev/null
    popd > /dev/null
    echo -e "\r[$1 installation] .. SUCCEED"
}

## Move to build.sh directory and
## convert relative path to absolute path
pushd $deps_path > /dev/null
deps_path=$PWD > $deps_path/install.log

## Information about installation
echo "-----------------------------------------------------"
echo "ARCUS PERL CLIENT DEPENDENCIES BUILD & INSTALL: START"
echo "-----------------------------------------------------"

## Install dependencies
install_path="$deps_path/../lib/Arcus/Deps"
zk_integration="--with-zookeeper=$install_path --enable-zk-integration"
build_and_install $zookeeper "--prefix=$install_path"
build_and_install $arcus_c_client "--prefix=$install_path $zk_integration"

popd > /dev/null

echo "---------------------------------------------------"
echo "ARCUS PERL CLIENT DEPENDENCIES BUILD & INSTALL: END"
echo "---------------------------------------------------"

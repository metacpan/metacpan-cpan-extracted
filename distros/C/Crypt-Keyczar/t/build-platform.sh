#!/bin/bash

DEBIAN="ubuntu:14.04 ubuntu:16.04 ubuntu:17.04 debian:7 debian:8 debian:9"
REDHAT="centos:6 centos:7"

FIXTURE_DEBIAN="apt-get update; apt-get upgrade -y; apt-get install -y build-essential libssl-dev libjson-perl"
FIXTURE_REDHAT="yum update -y; yum install -y make gcc openssl-devel perl-devel perl-Test-Simple perl-JSON"

PERL_MAKE_TEST="perl Makefile.PL; make test"


function test_platform() {
    local tags=$1
    local commands=$2
    for platform in $tags; do
        echo -n "${platform} ... "
        docker run -v $(pwd):/root -w /root --rm -i -t ${platform} /bin/bash -c \
            "echo build test ${platform}; ${commands}" > >(tee -a build.log > /dev/null) 2> >(tee -a build.log >&2)
        if [ $? = 0 ]; then
            echo "ok"
        else
            echo "FAIL, please look build.log"
        fi
    done
}


if [ $# = 1 ]; then
    docker run -v $(pwd):/root -w /root --rm -i -t $1 /bin/bash
    exit 0
fi
if [ $# = 2 ]; then
    docker run -v $(pwd):/root -w /root --rm -i -t $1 /bin/bash -c "$2"
    exit 0
fi
test_platform "$DEBIAN" "$FIXTURE_DEBIAN; $PERL_MAKE_TEST"
test_platform "$REDHAT" "$FIXTURE_REDHAT; $PERL_MAKE_TEST"

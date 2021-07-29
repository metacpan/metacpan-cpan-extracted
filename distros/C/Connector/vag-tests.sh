#!/bin/bash

set -e

cd /vagrant
perl Makefile.PL
make test

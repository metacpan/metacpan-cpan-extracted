#!/bin/bash

-e Makefile && make clean
perl Makefile.PL
make && make install

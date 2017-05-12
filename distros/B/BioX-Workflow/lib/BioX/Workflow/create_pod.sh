#!/usr/bin/bash

 ./template.pl Usage.tmpl |sed 's/\=encoding utf8//g' > Usage.pod

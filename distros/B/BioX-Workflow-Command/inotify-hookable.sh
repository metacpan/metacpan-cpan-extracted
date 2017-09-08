#!/usr/bin/env bash

RSYNC_BIOX="rsync -avz ../BioX-Workflow-Command  gencore@dalma.abudhabi.nyu.edu:/home/gencore/hpcrunner-test/"
export DEV='DEV'
inotify-hookable \
    --watch-directories lib \
    --watch-directories t \
    --watch-directories t \
    --watch-files t/test_class_tests.t \
    --on-modify-command "${RSYNC_BIOX}; prove -l -v t/test_class_tests.t"

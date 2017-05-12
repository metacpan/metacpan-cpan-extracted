#!/usr/bin/env bash

export DEV='DEV'
inotify-hookable \
    --watch-directories lib \
    --watch-directories t/lib/TestsFor/ \
    --watch-directories t/lib/TestMethod/ \
    --watch-files t/test_class_tests.t \
    --on-modify-command "prove -v t/test_class_tests.t"

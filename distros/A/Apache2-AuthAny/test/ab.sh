#!/bin/bash

TEST_PAGE=https://authany.cirg.washington.edu/demo/d3/demo.php

# Sign in and then grab your SID out of the userCookie table
AA_PID=10387726461268184698
CONCURRENCY=10
NUM_REQUESTS=10000

/usr/sbin/ab -q -c $CONCURRENCY -n $NUM_REQUESTS -C AA_PID=$AA_PID $TEST_PAGE

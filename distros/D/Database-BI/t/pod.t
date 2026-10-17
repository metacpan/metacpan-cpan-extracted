#!perl -w

# Author test: every POD in the distribution must parse, so a documentation
# defect is caught here rather than by a CPAN user (or by podchecker after
# upload).  Skips for anyone without Test::Pod, and does not run unless
# AUTHOR_TESTING is set -- see Test::DescribeMe.
#
#   AUTHOR_TESTING=1 prove -l t/pod.t

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::Pod' => '1.22' };

Test::Pod->import();

# lib and script are named explicitly: left to itself, Test::Pod searches blib/
# when a build directory exists, which is stale the moment lib/ is edited -- a
# check that reads a copy is not the check this test is for.
all_pod_files_ok(qw(lib script));

use 5.008001;
use strict;
use warnings;

use Test::More 0.96;
use Path::Tiny;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use CorpusTest;

test_corpus_file( path($0)->basename(".t") . ".json" );

done_testing;

#
# This file is part of BSON
#
# This software is Copyright (c) 2019 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:

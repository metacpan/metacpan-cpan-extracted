#!/usr/bin/env perl
# t/rls.t -- Phase 4.5: Row-level security
#
# RLS is deferred until multi-user mode is implemented (Phase 4.4 decision:
# stay single-user for now).  This file is a placeholder so the test suite
# reports a clear skip rather than a missing test file.

use strict;
use warnings;
use Test::More;

plan skip_all => 'Row-level security (4.5) deferred until multi-user mode (Phase 4.4)';

#!/usr/bin/env perl
use rlib '.';
use helper;
use Data::Dumper;
use B::DeparseTree::Fragment;  # for dump
use strict;
use English;

use feature (sprintf(":%vd", $^V)); # to avoid relying on the feature
                                    # logic to add CORE::

test_ops('listops.pm');
done_testing();

# B::DeparseTree::P518.pm
# Copyright (c) 2018 Rocky Bernstein
# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

use v5.14;

use rlib '../..';

package B::DeparseTree::P514;
use B::DeparseTree::P516;
use B::Deparse;
use strict;
use warnings ();

our(@EXPORT, @ISA);
our $VERSION = '3.2.0';
@ISA = qw(Exporter);

# Is the same as P518. Note however
# we import from B::Deparse and there are differences
# in those routines between 5.16 and 5.18
@ISA = qw(B::DeparseTree::P516);

# Copy unchanged functions from B::Deparse
# Note we pick up the version-specific copy
*begin_is_use = *B::Deparse::begin_is_use;

1;

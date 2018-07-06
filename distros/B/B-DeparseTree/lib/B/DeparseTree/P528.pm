# B::DeparseTree::P528.pm
# Copyright (c) 2018 Rocky Bernstein
# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

use rlib '../..';

package B::DeparseTree::P528;
use B::DeparseTree::P526;

use strict;
use warnings ();

our(@EXPORT, @ISA);
our $VERSION = '3.2.0';

# Is the same as P522. Note however
# we import from B::Deparse and there are differences
# in those routines between 5.22 and 5.24
@ISA = qw(B::DeparseTree::P526);

1;

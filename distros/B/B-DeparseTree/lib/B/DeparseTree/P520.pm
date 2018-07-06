# Copyright (c) 1998-2000, 2002, 2003, 2004, 2005, 2006 Stephen McCamant.
# Copyright (c) 2015, 2018 Rocky Bernstein
# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

# This is based on the module B::Deparse (for perl 5.20) by Stephen McCamant.
# It has been extended save tree structure, and is addressible
# by opcode address.

# B::Parse in turn is based on the module of the same name by Malcolm Beattie,
# but essentially none of his code remains.

use rlib '../..';

package B::DeparseTree::P520;
use B::DeparseTree::P518;

# Copy unchanged functions from B::Deparse
*find_scope_st = *B::Deparse::find_scope_st;
*meth_rclass_sv = *B::Deparse::meth_rclass_sv;
*meth_sv = *B::Deparse::meth_sv;
*rv2gv_or_string = *B::Deparse::rv2gv_or_string;

use strict;
use warnings ();

our(@EXPORT, @ISA);
our $VERSION = '3.2.0';

@ISA = qw(B::DeparseTree::P518);

1;

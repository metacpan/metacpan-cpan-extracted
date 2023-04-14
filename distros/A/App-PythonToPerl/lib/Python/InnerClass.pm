#
# This file is part of App-PythonToPerl
#
# This software is Copyright (c) 2023 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
# [[[ HEADER ]]]
# ABSTRACT: an inner class is a class defined inside of another class, in other words a nested class
#use RPerl;
package Python::InnerClass;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Python::Class);
use Python::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use Perl::Types;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::InnerClass',
    # all other properties inherited from Python::Class
};

# [[[ SUBROUTINES & OO METHODS ]]]

1;

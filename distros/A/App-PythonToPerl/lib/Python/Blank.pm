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
# ABSTRACT: a blank AKA empty line, containing no characters other than possibly newline
#use RPerl;
package Python::Blank;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Python::Component);
use Python::Component;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use Perl::Types;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::Blank',
    python_line_number_begin => my integer $TYPED_python_line_number_begin = undef,
    python_line_number_end => my integer $TYPED_python_line_number_end = undef,
    python_source_code => my string $TYPED_python_source_code = undef,
    perl_source_code => my string $TYPED_perl_source_code = undef,
};

# [[[ SUBROUTINES & OO METHODS ]]]

1;

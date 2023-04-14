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
# ABSTRACT: champ is like chomp, but better?
#use RPerl;
package Champ;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ EXPORTS ]]]
#use RPerl::Exporter qw(import);
use Exporter qw(import);
our @EXPORT = qw(champ);

# [[[ INCLUDES ]]]
use Perl::Types;

# [[[ SUBROUTINES ]]]

# NEED UPGRADE: move helper subroutine(s) into their own distribution
# NEED UPGRADE: move helper subroutine(s) into their own distribution
# NEED UPGRADE: move helper subroutine(s) into their own distribution

sub champ {
    # champ is like chomp, except it returns the chomped string instead of the number of characters removed, and does not alter the original
    { my string $RETURN_TYPE };
    ( my string $input_string ) = @ARG;

# NEED UPGRADE: need add error checking & graceful failure via croak()
# NEED UPGRADE: need add error checking & graceful failure via croak()
# NEED UPGRADE: need add error checking & graceful failure via croak()

    my string $output_string = $input_string;
    chomp $output_string;
    return $output_string;
}

1;

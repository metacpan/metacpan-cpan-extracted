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
# ABSTRACT: a shebang, denoting an executable script
#use RPerl;
package Python::Shebang;
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
    component_type => my string $TYPED_component_type = 'Python::Shebang',
    python_line_number_begin => my integer $TYPED_python_line_number_begin = undef,
    python_line_number_end => my integer $TYPED_python_line_number_end = undef,
    python_source_code => my string $TYPED_python_source_code = undef,
    perl_source_code => my string $TYPED_perl_source_code = undef,
};

# [[[ SUBROUTINES & OO METHODS ]]]

# PYSH01x
sub python_preparsed_to_perl_source {
# return translated Perl source code for pre-parsed Python component
    { my string $RETURN_TYPE };
    ( my Python::Shebang $self, my OpenAI::API $openai ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYSH010: undefined OpenAI API, croaking';
    }

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code}) or
        ($self->{python_source_code} eq q{})) {
        croak 'ERROR EPYSH011: non-existent or undefined or empty Python source code, croaking';
    }

#   $self->{perl_source_code} = '#!/usr/bin/perl';      # HARD-CODED OLD STYLE, MAY NOT WORK ON ALL OPERATING SYSTEMS?
    $self->{perl_source_code} = '#!/usr/bin/env perl';  # SOFT-CODED NEW STYLE, SHOULD  WORK ON ALL OPERATING SYSTEMS?

print 'in Function::Shebang->python_preparsed_to_perl_source(), about to return $self->{perl_source_code} = \'', $self->{perl_source_code}, '\'', "\n";
#die 'TMP DEBUG';

    # return Perl source code
    return $self->{perl_source_code};
}

1;

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
# ABSTRACT: a function decorator
#use RPerl;
package Python::FunctionDecorator;
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

# DEV NOTE: not actually used in this class, but needed so python_preparsed_to_perl_source() 
# can accept the same args as all Python::Component classes
use OpenAI::API;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::FunctionDecorator',
    # all other properties inherited from Python::Component
};

# [[[ SUBROUTINES & OO METHODS ]]]

# PYFD01x
sub python_preparsed_to_perl_source {
# return translated Perl source code for pre-parsed Python component
    { my string $RETURN_TYPE };
    ( my Python::FunctionDecorator $self, my OpenAI::API $openai ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYFD010: undefined OpenAI API, croaking';
    }

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code}) or
        ($self->{python_source_code} eq q{})) {
        croak 'ERROR EPYFD011: non-existent or undefined or empty Python source code, croaking';
    }

# START HERE: translate function decorators, including indentation as appropriate
# START HERE: translate function decorators, including indentation as appropriate
# START HERE: translate function decorators, including indentation as appropriate

#    $self->{perl_source_code} = '# ' . $self->{python_source_code} . '  # DUMMY PERL SOURCE CODE, NEED TRANSLATE!';
    $self->{perl_source_code} = $self->python_source_code_indentation() . '# ' . $self->python_source_code_without_indentation() . '  # DUMMY PERL SOURCE CODE, NEED TRANSLATE!';

print 'in Function::Decorator->python_preparsed_to_perl_source(), about to return $self->{perl_source_code} = \'', $self->{perl_source_code}, '\'', "\n";
#die 'TMP DEBUG';

    # return Perl source code
    return $self->{perl_source_code};
}

1;

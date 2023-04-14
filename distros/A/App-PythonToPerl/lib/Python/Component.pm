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
#use RPerl;
package Python::Component;
use strict;
use warnings;
our $VERSION = 0.002_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Class);
use Perl::Type::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use Perl::Types;

# DEV NOTE: not actually used in this class, but needed so python_preparsed_to_perl_source() 
# can accept the same args as all Python::Component classes
use OpenAI::API;

# [[[ ADDITIONAL CLASSES ]]]
package Python::Component::arrayref; 1;
package Python::Component::hashref; 1;

package Python::Component;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::Component',
    python_line_number_begin => my integer $TYPED_python_line_number_begin = undef,
    python_line_number_end => my integer $TYPED_python_line_number_end = undef,
    python_source_code => my string $TYPED_python_source_code = undef,
    perl_source_code => my string $TYPED_perl_source_code = undef,
};

# [[[ SUBROUTINES & OO METHODS ]]]

# DEV NOTE: the below subroutines are meant to be inherited by the other Python::Component child classes
# which do not need real de-parsing or translation algorithms, such as Python::Blank and Python::Whitespace, 
# or which are already translated during the pre-parse stage, such as Python::Comment etc.

# PYCP00x
sub python_preparsed_to_python_source {
# return Python source code for pre-parsed Python component
    { my string $RETURN_TYPE };
    ( my Python::Component $self ) = @ARG;

    # DEV NOTE, PYCP000: $openai not used in Python-to-Python de-parse round-tripping, no need to error check

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code})) {
        croak 'ERROR EPYCP001: non-existent or undefined Python source code, croaking';
    }
    elsif (($self->{python_source_code} eq q{}) and
            not $self->isa('Python::Blank')) {
        carp 'WARNING WPYCP001: empty Python source code';
    }

    # DEV NOTE, PYCP002: $self->{python_preparsed} may or may not be used by classes which inherit this subroutine, no need to error check

    # return original Python source code
    return $self->{python_source_code};
}


# PYCP01x
sub python_preparsed_to_perl_source {
# return translated Perl source code for pre-parsed Python component
    { my string $RETURN_TYPE };
    ( my Python::Component $self, my OpenAI::API $openai ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYCP010: undefined OpenAI API, croaking';
    }

    # DEV NOTE, PYCP011: $self->{python_source_code} not used in this translation, no need to error check

    # DEV NOTE, PYCP012: $self->{python_preparsed} may or may not be used by classes which inherit this subroutine, no need to error check

    # error or warning if no Perl source code
    if ((not exists  $self->{perl_source_code}) or
        (not defined $self->{perl_source_code})) {

        return '# DUMMY PERL SOURCE CODE, NEED TRANSLATE!';  # TEMPORARY DEBUG, NEED DELETE!

        croak 'ERROR EPYCP013: non-existent or undefined Perl source code, croaking';
    }
    elsif (($self->{perl_source_code} eq q{}) and
            not $self->isa('Python::Blank')) {
        carp 'WARNING WPYCP013: empty Perl source code';
    }

    # return Perl source code
    return $self->{perl_source_code};
}


# PYCP02x
sub python_source_code_indentation {
# return indentation of first line of Python source code
    { my string $RETURN_TYPE };
    ( my Python::Component $self ) = @ARG;

    $self->{python_source_code} =~ m/^(\s*)[^\s]/;

print 'in python_source_code_indentation(), about to return indentation $1 = \'', $1, '\'', "\n";
    return $1;
}


# PYCP03x
sub python_source_code_without_indentation {
# return first line of Python source code without indentation
    { my string $RETURN_TYPE };
    ( my Python::Component $self ) = @ARG;

    $self->{python_source_code} =~ m/^\s*([^\s].*)$/;

print 'in python_source_code_indentation(), about to return Python source code without indentation $1 = \'', $1, '\'', "\n";
    return $1;
}

1;

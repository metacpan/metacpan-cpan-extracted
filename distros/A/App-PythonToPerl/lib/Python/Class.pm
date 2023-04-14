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
package Python::Class;
use strict;
use warnings;
our $VERSION = 0.007_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Python::Component);
use Python::Component;

# [[[ DATA TYPES ]]]
package Python::Class::hashref::hashref; 1;
package Python::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use Perl::Types;
use OpenAI::API;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::Class',
    indentation => my string $TYPED_indentation = undef,
    symbol => my string $TYPED_symbol = undef,
    symbol_scoped => my string $TYPED_symbol_scoped = undef,
    parents => my string $TYPED_parents = undef,
    python_file_path => my string $TYPED_python_file_path = undef,
    python_line_number_begin => my integer $TYPED_python_line_number_begin = undef,
    python_line_number_end => my integer $TYPED_python_line_number_end = undef,
    python_line_number_end_header => my integer $TYPED_python_line_number_end_header = undef,
    python_source_code => my string $TYPED_python_source_code = undef,
    python_source_code_full => my string $TYPED_python_source_code_full = undef,
    python_preparsed => my Python::Component::arrayref $TYPED_python_preparsed = undef,
    perl_source_code => my string $TYPED_perl_source_code = undef,
};

# [[[ SUBROUTINES & OO METHODS ]]]

# NEED UPGRADE: check python_source_code_full to avoid repeated de-parsing, and perl_source_code_full to avoid repeated translating
# NEED UPGRADE: check python_source_code_full to avoid repeated de-parsing, and perl_source_code_full to avoid repeated translating
# NEED UPGRADE: check python_source_code_full to avoid repeated de-parsing, and perl_source_code_full to avoid repeated translating

# PYCL00x
sub python_preparsed_to_python_source {
# return Python source code
    { my string $RETURN_TYPE };
    ( my Python::Class $self ) = @ARG;

    # DEV NOTE, PYCL000: $openai not used in Python-to-Python de-parse round-tripping, no need to error check

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code})) {
        croak 'ERROR EPYCL001: non-existent or undefined Python source code, croaking';
    }
    elsif ($self->{python_source_code} eq '') {
        carp 'WARNING WPYCL001: empty Python source code';
    }

    # error or warning if no pre-parsed components
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
        croak 'ERROR EPYCL002: non-existent or undefined Python pre-parsed components, croaking';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYCL002: empty Python pre-parsed components';
    }

    # initialize property that will store de-parsed source code;
    # save fully de-parsed Python source code, to avoid repeated de-parsing
    $self->{python_source_code_full} = '';

    # class header goes before class body
    $self->{python_source_code_full} = $self->{python_source_code} . "\n";

    # de-parse class body
    foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed}}) {
print 'in Python::Class->python_preparsed_to_python_source(), class \'', $self->{symbol_scoped}, '\', de-parsing class body, about to call python_preparsed_to_python_source()...', "\n";
        $self->{python_source_code_full} .= $python_preparsed_component->python_preparsed_to_python_source() . "\n";
print 'in Python::Class->python_preparsed_to_python_source(), class \'', $self->{symbol_scoped}, '\', de-parsing class body, ret from call python_preparsed_to_python_source()', "\n";
    }

    # remove extra trailing newline, to match original input source code
    chomp $self->{python_source_code_full};

    # return de-parsed Python source code
    return $self->{python_source_code_full};
}


# PYCL01x
sub python_preparsed_to_perl_source {
# return Perl source code
    { my string $RETURN_TYPE };
    ( my Python::Class $self, my OpenAI::API $openai ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYCL010: undefined OpenAI API, croaking';
    }

    # DEV NOTE, PYCL011: $self->{python_source_code} not used in this translation, no need to error check

    # error or warning if no pre-parsed components
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
        croak 'ERROR EPYCL012: non-existent or undefined Python pre-parsed components, croaking';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYCL012: empty Python pre-parsed components';
    }

    # initialize property that will store de-parsed & translated source code;
    # save fully translated Perl source code, to avoid repeated translating
    $self->{perl_source_code_full} = '';

    # package Foo::Baz; use strict; use warnings; use parent qw(Foo Bar); use Foo; use Bar;
    # class header goes before class body

    # class symbol AKA class name
    if ((not exists $self->{symbol}) or
        (not defined $self->{symbol}) or
        ($self->{symbol} eq '')) {
        croak 'ERROR EPYCL013a: non-existent or undefined or empty class symbol, croaking';
    }
    if ((not exists $self->{indentation}) or
        (not defined $self->{indentation})) {
        croak 'ERROR EPYCL013b: non-existent or undefined class indentation, croaking';
    }

    my string $symbol_scoped_perl = $self->{symbol};
    $symbol_scoped_perl =~ s/\./::/g;  # replace Python's dot '.' scope delimiter with Perl's double colon '::' scope delimiter
    $self->{perl_source_code_full} .= $self->{indentation} . 'package ' . $symbol_scoped_perl . ';';

# NEED ANSWER: is it correct to insert the strict & warnings pragmas inside each class header like this, or should they be elsewhere?
# NEED ANSWER: is it correct to insert the strict & warnings pragmas inside each class header like this, or should they be elsewhere?
# NEED ANSWER: is it correct to insert the strict & warnings pragmas inside each class header like this, or should they be elsewhere?

    # enable strict & warnings pragmas for all classes
    $self->{perl_source_code_full} .= ' use strict; use warnings;';


# NEED FIX: how to handle equal signs in the class parents?
# NEED FIX: how to handle equal signs in the class parents?
# NEED FIX: how to handle equal signs in the class parents?

# class Foo(Bar, Bat, metaclass=Quux):


    # parent classes of this class
    if ((exists $self->{parents}) and (defined $self->{parents})) {
        if ($self->{parents} eq '') {
            carp 'WARNING WPYCL014: defined but empty class parents, carping';
        }
        my string::arrayref $parents_split = [split /\s*,\s*/, $self->{parents}];
        my string::arrayref $parents_split_perl = [];
        my string::arrayref $parents_split_perl_use = [];
        if ((scalar @{$parents_split}) > 0) {
            $self->{perl_source_code_full} .= ' use parent qw(';
            foreach my string $parent_split (@{$parents_split}) {

# NEED UPGRADE: keep multi-line class headers as multi-line, and preserve trailing comments
# NEED UPGRADE: keep multi-line class headers as multi-line, and preserve trailing comments
# NEED UPGRADE: keep multi-line class headers as multi-line, and preserve trailing comments

                # trim trailing comments
                if ($parent_split =~ m/^(.*)\s*(\#.*)$/) {
                    $parent_split = $1;
print 'in Python::Class->python_preparsed_to_perl_source(), parent class \'', $1, '\', trimming trailing comment \'', $2, '\'', "\n";
                }

                $parent_split =~ s/\./::/g;  # replace Python's dot '.' scope delimiter with Perl's double colon '::' scope delimiter
                push @{$parents_split_perl}, $parent_split;
                push @{$parents_split_perl_use}, 'use ' . $parent_split . ';';
            }
            $self->{perl_source_code_full} .= join ' ', @{$parents_split_perl};
            $self->{perl_source_code_full} .= ');';
            $self->{perl_source_code_full} .= ' ' . join ' ', @{$parents_split_perl_use};
        }
    }

    # newline after class header
    $self->{perl_source_code_full} .= "\n";

print 'in Python::Class->python_preparsed_to_perl_source(), class \'', $self->{symbol_scoped}, '\', after translating class header, have $self->{perl_source_code_full} = \'', $self->{perl_source_code_full}, '\'', "\n";

    # de-parse & translate class body
    foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed}}) {
print 'in Python::Class->python_preparsed_to_perl_source(), class \'', $self->{symbol_scoped}, '\', de-parsing & translating class body, about to call python_preparsed_to_perl_source()...', "\n";
        $self->{perl_source_code_full} .= $python_preparsed_component->python_preparsed_to_perl_source($openai) . "\n";
print 'in Python::Class->python_preparsed_to_perl_source(), class \'', $self->{symbol_scoped}, '\', de-parsing & translating class body, ret from call python_preparsed_to_perl_source()', "\n";
    }


# NEED ANSWER: is it safe to omit the customary hard-coded '1;' at the end of each Perl package, or at least the last package in a file???
# NEED ANSWER: is it safe to omit the customary hard-coded '1;' at the end of each Perl package, or at least the last package in a file???
# NEED ANSWER: is it safe to omit the customary hard-coded '1;' at the end of each Perl package, or at least the last package in a file???


    # remove extra trailing newline, to match original input source code
    chomp $self->{perl_source_code_full};

    # return de-parsed & translated Perl source code
    return $self->{perl_source_code_full};
}

1;

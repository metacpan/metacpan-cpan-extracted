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
package Python::Function;
use strict;
use warnings;
our $VERSION = 0.015_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Python::Component);
use Python::Component;

# [[[ DATA TYPES ]]]
package Python::Function::hashref::hashref; 1;
package Python::Function;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use Perl::Types;
use OpenAI::API;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::Function',
    decorators => my string $TYPED_decorators = undef,
    indentation => my string $TYPED_indentation = undef,
    symbol => my string $TYPED_symbol = undef,
    symbol_scoped => my string $TYPED_symbol_scoped = undef,
    arguments => my string $TYPED_arguments = undef,
    return_type => my string $TYPED_return_type = undef,
    python_file_path => my string $TYPED_python_file_path = undef,
    python_line_number_begin => my integer $TYPED_python_line_number_begin = undef,
    python_line_number_end => my integer $TYPED_python_line_number_end = undef,
    python_line_number_end_header => my integer $TYPED_python_line_number_end_header = undef,
    python_source_code => my string $TYPED_python_source_code = undef,
    python_source_code_full => my string $TYPED_python_source_code_full = undef,
    python_preparsed => my Python::Component::arrayref $TYPED_python_preparsed = undef,
    python_preparsed_decorators => my Python::Component::arrayref $TYPED_python_preparsed_decorators = undef,
    perl_source_code => my string $TYPED_perl_source_code = undef,
    perl_source_code_full => my string $TYPED_perl_source_code_full = undef,
};

# [[[ SUBROUTINES & OO METHODS ]]]

# NEED UPGRADE: check python_source_code_full to avoid repeated de-parsing, and perl_source_code_full to avoid repeated translating
# NEED UPGRADE: check python_source_code_full to avoid repeated de-parsing, and perl_source_code_full to avoid repeated translating
# NEED UPGRADE: check python_source_code_full to avoid repeated de-parsing, and perl_source_code_full to avoid repeated translating

# PYFU00x
sub python_preparsed_to_python_source {
# return Python source code
    { my string $RETURN_TYPE };
    ( my Python::Function $self ) = @ARG;

    # DEV NOTE, PYFU000: $openai not used in Python-to-Python de-parse round-tripping, no need to error check

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code})) {
        croak 'ERROR EPYFU001: non-existent or undefined Python source code, croaking';
    }
    elsif ($self->{python_source_code} eq '') {
        carp 'WARNING WPYFU001: empty Python source code';
    }

    # error or warning if no pre-parsed components
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
        croak 'ERROR EPYFU002: non-existent or undefined Python pre-parsed components, croaking';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYFU002: empty Python pre-parsed components';
    }

    # initialize property that will store de-parsed source code;
    # save fully de-parsed Python source code, to avoid repeated de-parsing
    $self->{python_source_code_full} = '';

    # de-parse function header decorators, if present
    if ((exists $self->{python_preparsed_decorators}) and
        (defined $self->{python_preparsed_decorators})) {

        foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed_decorators}}) {
print 'in Python::Function->python_preparsed_to_python_source(), function \'', $self->{symbol_scoped}, '\', de-parsing function header decorators, about to call python_preparsed_to_python_source()...', "\n";
            $self->{python_source_code_full} .= $python_preparsed_component->python_preparsed_to_python_source() . "\n";
print 'in Python::Function->python_preparsed_to_python_source(), function \'', $self->{symbol_scoped}, '\', de-parsing function header decorators, ret from call python_preparsed_to_python_source()', "\n";
        }
    }

    # function header goes in between decorators and function body
    $self->{python_source_code_full} .= $self->{python_source_code} . "\n";

    # de-parse function body
    foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed}}) {
print 'in Python::Function->python_preparsed_to_python_source(), function \'', $self->{symbol_scoped}, '\', de-parsing function body, about to call python_preparsed_to_python_source()...', "\n";
        $self->{python_source_code_full} .= $python_preparsed_component->python_preparsed_to_python_source() . "\n";
print 'in Python::Function->python_preparsed_to_python_source(), function \'', $self->{symbol_scoped}, '\', de-parsing function body, ret from call python_preparsed_to_python_source()', "\n";
    }

    # remove extra trailing newline, to match original input source code
    chomp $self->{python_source_code_full};

    # return de-parsed Python source code
    return $self->{python_source_code_full};
}


# PYFU01x
sub python_preparsed_to_perl_source {
# return Perl source code
    { my string $RETURN_TYPE };
    ( my Python::Function $self, my OpenAI::API $openai ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYFU010: undefined OpenAI API, croaking';
    }

    # DEV NOTE, PYFU011: $self->{python_source_code} not used in this translation, no need to error check

    # error or warning if no pre-parsed components
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
        croak 'ERROR EPYFU012: non-existent or undefined Python pre-parsed components, croaking';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYFU012: empty Python pre-parsed components';
    }

    # initialize property that will store de-parsed & translated source code;
    # save fully translated Perl source code, to avoid repeated translating
    $self->{perl_source_code_full} = '';

    # de-parse & translate function header decorators, if present
    if ((exists $self->{python_preparsed_decorators}) and
        (defined $self->{python_preparsed_decorators})) {

        foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed_decorators}}) {
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', de-parsing & translating function header decorators, about to call python_preparsed_to_perl_source()...', "\n";
            $self->{perl_source_code_full} .= $python_preparsed_component->python_preparsed_to_perl_source($openai) . "\n";
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', de-parsing & translating function header decorators, ret from call python_preparsed_to_perl_source()', "\n";
        }
    }



# NEED FIX: convert $self->{return_type} from Python to Perl type system
# NEED FIX: convert $self->{return_type} from Python to Perl type system
# NEED FIX: convert $self->{return_type} from Python to Perl type system

    # sub FOO { { my footype $RETURN_TYPE }; ( my footype $arg1, my bartype $arg2 ) = @ARG;
    # function header goes in between decorators and function body

    # function symbol AKA function name
    if ((not exists $self->{symbol}) or
        (not defined $self->{symbol}) or
        ($self->{symbol} eq '')) {
        croak 'ERROR EPYFU013a: non-existent or undefined or empty function symbol, croaking';
    }
    if ((not exists $self->{indentation}) or
        (not defined $self->{indentation})) {
        croak 'ERROR EPYFU013b: non-existent or undefined function indentation, croaking';
    }
    $self->{perl_source_code_full} .= $self->{indentation} . 'sub ' . $self->{symbol} . ' {';

    # function return type
    if ((not exists $self->{return_type}) or (not defined $self->{return_type}) or ($self->{return_type} eq '')) {
        carp 'WARNING WPYFU014: non-existent or undefined or empty function return type, setting to \'unknown\', carping';
        $self->{return_type} = 'unknown';
    }
    $self->{perl_source_code_full} .= ' { my ' . $self->{return_type} .  ' $RETURN_TYPE };';
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', after translating function return type, have $self->{perl_source_code_full} = \'', $self->{perl_source_code_full}, '\'', "\n";

    # function arguments
    if ((exists $self->{arguments}) and (defined $self->{arguments})) {
        if ($self->{arguments} eq '') {
            carp 'WARNING WPYFU015: defined but empty function arguments, carping';
        }
        my string::arrayref $arguments_split = [split /\s*,\s*/, $self->{arguments}];
        my string::arrayref $arguments_split_perl = [];

        if ($self->isa('Python::Method')) {
            if ((scalar @{$arguments_split}) == 0) {
                carp 'WARNING WPYFU016: method \'', $self->{symbol_scoped}, '\', missing \'self\' argument, no arguments provided, carping';
            }
            elsif ($arguments_split->[0] ne 'self') {
                if ( grep( /^self$/, @{$arguments_split} ) ) {
                    carp 'WARNING WPYFU017a: method \'', $self->{symbol_scoped},
                        '\', \'self\' argument present but not first argument provided, not setting data type as class name, carping';
                }
                else {
                    carp 'WARNING WPYFU017b: method \'', $self->{symbol_scoped},
                        '\', missing \'self\' argument, not present in arguments provided, carping';
                }

                $self->{perl_source_code_full} .= $self->python_preparsed_to_perl_source_arguments($arguments_split, $arguments_split_perl);
            }
            else {
                if ((not exists $self->{scope}) or (not defined $self->{scope}) or ($self->{scope} eq '')) {
                    croak 'ERROR EPYFU018: method \'', $self->{symbol_scoped},
                        '\', missing \'scope\' object property, croaking';
                }
                # we know the first argument is correctly set to 'self', because we did not trigger the `ne 'self'` check above;
                # current scope is the name of this method's enclosing class, so that is the same as the name of the $self data type;
                # set $self data type and use `shift` to discard 'self' from the split arguments array
                push @{$arguments_split_perl}, ('my ' . $self->{scope} . ' $self');
                shift @{$arguments_split};

                $self->{perl_source_code_full} .= $self->python_preparsed_to_perl_source_arguments($arguments_split, $arguments_split_perl);
            }
        }
        else {  # not a method, either a normal function or an inner function
            if ((scalar @{$arguments_split}) > 0) {
                $self->{perl_source_code_full} .= $self->python_preparsed_to_perl_source_arguments($arguments_split, $arguments_split_perl);
            }
        }
    }




    # keep Perl source code split by component, for active component checking below
    my string::arrayref $perl_source_code_split = [];

    # if there are any active components (anything other than comments and whitespace and blank lines) in the function body,
    # then record the $perl_source_code_split index of the last active component;
    # used to place the final closing curly brace and thus maintain the original line count
    my boolean $final_active_component_index = -1;

    # de-parse & translate function body
    foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed}}) {
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', de-parsing & translating function body, about to call python_preparsed_to_perl_source() on $python_preparsed_component = ', Dumper($python_preparsed_component), "\n";
        push @{$perl_source_code_split}, $python_preparsed_component->python_preparsed_to_perl_source($openai);
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', de-parsing & translating function body, ret from call to python_preparsed_to_perl_source(), received $perl_source_code_split->[-1] = \'', $perl_source_code_split->[-1], '\'', "\n";

        if ((not $python_preparsed_component->isa('Python::Comment')) and
            (not $python_preparsed_component->isa('Python::Whitespace')) and
            (not $python_preparsed_component->isa('Python::Blank'))) {
            $final_active_component_index = (scalar @{$perl_source_code_split}) - 1;
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', de-parsing & translating function body, updated $final_active_component_index = ', $final_active_component_index, "\n";
        }

print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', de-parsing & translating function body, ret from call python_preparsed_to_perl_source()', "\n";
    }

    # close function body with curly brace, placed after the final active component in the function body, 
    # or directly after the function header if no active components in body
    my string $function_end = ' }  # END sub ' . $self->{symbol} . '()'; 
    if ($final_active_component_index > -1) {
        # end function after final active component in function body,
        # with trailing comment to label closing curly brace as end of function
        $perl_source_code_split->[$final_active_component_index] .= $function_end;
#        $perl_source_code_split->[$final_active_component_index] .= '  ## ACTIVE BODY COMPONENT';
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', appending closing curly brace after final active component in function body, have $perl_source_code_split->[', $final_active_component_index, '] = \'', $perl_source_code_split->[$final_active_component_index], '\'', "\n";
    }
    else {
        $self->{perl_source_code_full} .= $function_end;
#        $self->{perl_source_code_full} .= '  ## HEADER COMPONENT';
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', appending closing curly brace after function header due to lack of any active components in function body, have $self->{perl_source_code_full} = \'', $self->{perl_source_code_full}, '\'', "\n";
    }

    # assemble Perl source code in function body, if present
    if ((scalar @{$perl_source_code_split}) > 0) {
        $self->{perl_source_code_full} .= "\n";  # newline after function header
        $self->{perl_source_code_full} .= join "\n", @{$perl_source_code_split};
print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\' assembling generated Perl source code from non-empty function body $perl_source_code_split = ', Dumper($perl_source_code_split), "\n";
    }

print 'in Python::Function->python_preparsed_to_perl_source(), function \'', $self->{symbol_scoped}, '\', about to return $self->{perl_source_code_full} = \'', $self->{perl_source_code_full}, '\'', "\n";
#    if ($final_active_component_index > -1) {
#die 'TMP DEBUG';
#    }

    # return de-parsed & translated Perl source code
    return $self->{perl_source_code_full};
}


# PYFU02x
sub python_preparsed_to_perl_source_arguments {
# return Perl source code for function arguments
    { my string $RETURN_TYPE };
    ( my Python::Function $self, my string::arrayref $arguments_split, my string::arrayref $arguments_split_perl ) = @ARG;
print 'in Python::Function->python_preparsed_to_perl_source_arguments(), function \'', $self->{symbol_scoped}, '\', top of subroutine', "\n";

# NEED FIX: implement Python-to-Perl translation for arguments with default values provided
# NEED FIX: implement Python-to-Perl translation for arguments with default values provided
# NEED FIX: implement Python-to-Perl translation for arguments with default values provided

# NEED FIX: handle non-positional function arguments appearing after '*' parameter delimiter
# NEED FIX: handle non-positional function arguments appearing after '*' parameter delimiter
# NEED FIX: handle non-positional function arguments appearing after '*' parameter delimiter

# NEED FIX: handle **kwargs & other special function arguments
# NEED FIX: handle **kwargs & other special function arguments
# NEED FIX: handle **kwargs & other special function arguments

# def __FOO__(self, *, BAR=None, var_BAR=1e-9, force_alpha="warn"):
# def FOO_BAR(code, extra_preargs=[], extra_postargs=[]):

    my string $perl_source_code = ' ( ';
    foreach my string $argument_split (@{$arguments_split}) {

# NEED UPGRADE: keep multi-line function headers as multi-line, and preserve trailing comments
# NEED UPGRADE: keep multi-line function headers as multi-line, and preserve trailing comments
# NEED UPGRADE: keep multi-line function headers as multi-line, and preserve trailing comments

        # trim trailing comments
        if ($argument_split =~ m/^(.*)\s*(\#.*)$/) {
            $argument_split = $1;
print 'in Python::Function->python_preparsed_to_perl_source_arguments(), argument \'', $1, '\', trimming trailing comment \'', $2, '\'', "\n";
        }

        # handle argument names
        if ($argument_split eq '*') {
            push @{$arguments_split_perl}, 'my void $ASTERISK';
        }
        elsif ($argument_split eq '**kwargs') {
            push @{$arguments_split_perl}, 'my void $KWARGS';
        }
        else {
            push @{$arguments_split_perl}, ('my unknown $' . $argument_split);
        }
    }
    $perl_source_code .= join ', ', @{$arguments_split_perl};
    $perl_source_code .= ' ) = @ARG;';

print 'in Python::Function->python_preparsed_to_perl_source_arguments(), function \'', $self->{symbol_scoped}, '\', about to return $perl_source_code = \'', $perl_source_code, '\'', "\n";
    return $perl_source_code;
}

1;

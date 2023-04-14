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
package Python::File;
use strict;
use warnings;
our $VERSION = 0.022_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Python::Component);
use Python::Component;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
# system includes
use Perl::Types;
#use re 'debugcolor';  # output regex debugging info
use File::Spec;  # for splitpath() and catpath()
use Fcntl qw( :mode );  # for S_IXUSR etc;  https://perldoc.perl.org/perlfunc#stat

# internal includes
use Champ;
use Python::Shebang;
use Python::Blank;
use Python::Whitespace;
use Python::Comment;
use Python::CommentSingleQuotes;
use Python::CommentDoubleQuotes;
use Python::Include;
use Python::FunctionDecorator;
use Python::Function;
use Python::InnerFunction;
use Python::Method;
use Python::Class;
use Python::InnerClass;
use Python::LocalClass;
use Python::Unknown;

# external (3rd party) includes
use OpenAI::API;

# [[[ ADDITIONAL CLASSES ]]]
package Python::File::arrayref; 1;
package Python::File::hashref; 1;

package Python::File;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::File',
    python_file_path => my string $TYPED_python_file_path = undef,
    python_source_code => my string $TYPED_python_source_code = undef,  # original source code, read from the Python input file
    python_source_code_full => my string $TYPED_python_source_code_full = undef,  # de-parsed source code, made from pre-parsed components
    python_preparsed => my Python::Component::arrayref $TYPED_python_preparsed = undef,  # source code, pre-parsed into Perl data structures
    perl_file_path => my string $TYPED_perl_file_path = undef,
#    perl_source_code => my string $TYPED_perl_source_code = undef,  # in Python::File, perl_source_code is same as perl_source_code_full
    perl_source_code_full => my string $TYPED_perl_source_code_full = undef,
};

# [[[ SUBROUTINES & OO METHODS ]]]

# PYFI05x
sub python_file_to_perl_file {
# translate Python file into Perl and save Perl file
# translate a file of Python source code into Perl, and save the new Perl file
    { my string $RETURN_TYPE };
    (   my Python::File $self,
        my OpenAI::API $openai,
        my Python::Include::hashref $python_includes,
        my Python::Function::hashref $python_functions,
        my Python::Class::hashref $python_classes
    ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYFI050: undefined OpenAI API, croaking';
    }

    # DEV NOTE, PYFI051: $self->{python_source_code} not used in this translation, no need to error check

    # PRE-PARSE PYTHON FILE
#print 'in python_file_to_perl_file(), about to call python_file_to_python_preparsed()...', "\n";
    # DEV NOTE: capturing the return value below is purely optional,
    # the pre-parsed data structures output will also be stored in the Python::File object's python_preparsed property 
#    my Python::Component::arrayref $python_preparsed =
        $self->python_file_to_python_preparsed( $python_includes, $python_functions, $python_classes);
#print 'in python_file_to_perl_file(), ret from python_file_to_python_preparsed(), have     $self = ', Dumper($self), "\n";
#print 'in python_file_to_perl_file(), ret from python_file_to_python_preparsed(), have     $python_files = ', Dumper($python_files), "\n";
print 'in python_file_to_perl_file(), ret from python_file_to_python_preparsed(), have $self->{python_preparsed} = ', Dumper($self->{python_preparsed}), "\n";
#print 'in python_file_to_perl_file(), have $python_includes = ', Dumper($python_includes), "\n";
#print 'in python_file_to_perl_file(), have $python_functions = ', Dumper($python_functions), "\n";
#print 'in python_file_to_perl_file(), have $python_classes = ', Dumper($python_classes), "\n";

    # error or warning if no pre-parsed components
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
        croak 'ERROR EPYFI052: non-existent or undefined Python pre-parsed components, croaking';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYFI052: empty Python pre-parsed components, carping';
    }

    # DE-PARSE PYTHON FILE BACK INTO PYTHON AKA ROUND-TRIPPING
print 'in python_file_to_perl_file(), about to call python_preparsed_to_python_source()...', "\n";
    # DEV NOTE: capturing the return value below is purely optional,
    # the source code output will also be stored in the Python::File object's python_source_code_full property 
#    my string $python_source_code = 
        $self->python_preparsed_to_python_source();
print 'in python_file_to_perl_file(), ret from python_preparsed_to_python_source(), have $self->{python_source_code_full} = ', "\n", $self->{python_source_code_full}, "\n";
#die 'TMP DEBUG, PYTHON ROUND-TRIPPING';

    # DE-PARSE & TRANSLATE PYTHON FILE INTO PERL SOURCE CODE
print 'in python_file_to_perl_file(), about to call python_preparsed_to_perl_source()...', "\n";
    # DEV NOTE: capturing the return value below is purely optional,
    # the source code output will also be stored in the Python::File object's perl_source_code_full property 
#    my string $perl_source_code = 
        $self->python_preparsed_to_perl_source($openai);
print 'in python_file_to_perl_file(), ret from python_preparsed_to_perl_source(), have $self->{perl_source_code_full} = ', "\n", $self->{perl_source_code_full}, "\n";

    # SAVE PERL FILE
print 'in python_file_to_perl_file(), about to call python_file_path_to_perl_file_path()...', "\n";
    # DEV NOTE: capturing the return value below is purely optional,
    # the file name output will also be stored in the Python::File object's perl_file_path property 

    # generate Perl file path based on Python file path
#    my string $perl_file_path = 
        $self->python_file_path_to_perl_file_path();
print 'in python_file_to_perl_file(), ret from python_file_path_to_perl_file_path(), have $self->{perl_file_path} = \'', $self->{perl_file_path}, '\'', "\n";

    # open new Perl source code file, write all contents to disk, close file
print 'in python_file_to_perl_file(), about to save Perl file...', "\n";
    open (my filehandleref $PERL_FILE, '>', $self->{perl_file_path})
        or croak 'ERROR EPYFI05x: failed to open Perl source code file \'', $self->{perl_file_path}, 
            '\' for writing, received OS error message \'', $OS_ERROR, '\', croaking';  # DEV NOTE: $OS_ERROR == $!
    print {$PERL_FILE} $self->{perl_source_code_full};
    close($PERL_FILE)
        or croak 'ERROR EPYFI05y: failed to close Perl source code file \'', $self->{perl_file_path}, 
            '\' after writing, received OS error message \'', $OS_ERROR, '\', croaking';
print 'in python_file_to_perl_file(), ret from calls to save Perl file', "\n";

    # set file executability permission based on presence of shebang;
    # an executable script has a shebang, a non-executable module AKA library does not have a shebang
    if((defined $self->{python_preparsed}->[0]) and ($self->{python_preparsed}->[0]->isa('Python::Shebang'))) {
print 'in python_file_to_perl_file(), setting executable permission of Perl file', "\n";
        chmod(S_IXUSR, $self->{perl_file_path})
            or croak 'ERROR EPYFI05z: failed to chmod u+x Perl source code file \'', $self->{perl_file_path}, 
                '\' after closing, received OS error message \'', $OS_ERROR, '\', croaking';
    }

print 'in python_file_to_perl_file(), about to return $self->{perl_file_path} = \'', $self->{perl_file_path}, '\'', "\n";
    return $self->{perl_file_path};
}


# PYFI04x
sub python_file_path_to_perl_file_path {
# convert Python file path to Perl file path
    { my string $RETURN_TYPE };
    ( my Python::File $self ) = @ARG;

    # DEV NOTE, PYFI040: $openai not used in this subroutine, no need to error check
    # DEV NOTE, PYFI041: $self->{python_source_code} not used in this subroutine, no need to error check

    # error or warning if no pre-parsed components;
    # must have already pre-parsed to check for shebang
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
#        croak 'ERROR EPYFI042a: non-existent or undefined Python pre-parsed components, croaking';
        carp 'WARNING WPYFI042a: non-existent or undefined Python pre-parsed components, carping';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYFI042b: empty Python pre-parsed components, carping';
    }

    # error if no file path
    if ((not exists  $self->{python_file_path}) or
        (not defined $self->{python_file_path}) or
        ($self->{python_file_path} eq '')) {
        croak 'ERROR EPYFI043: non-existent or undefined or empty Python file path, croaking';
    }

    # split file path into volume (ignored in Unix operating systems), directory, and file name
    my string $python_volume;
    my string $python_directory;
    my string $python_file_name;
    ($python_volume, $python_directory, $python_file_name) = File::Spec->splitpath($self->{python_file_path});

    # ensure file name was split correctly
    if ((not defined $python_file_name) or
        ($python_file_name eq '')) {
        croak 'ERROR EPYFI044: undefined or empty Python file name, croaking';
    }

    # always base Perl file name on original Python file name
    my string $perl_file_name = $python_file_name;

    # set file suffix based on presence of shebang;
    # an executable script has a shebang, a non-executable module AKA library does not have a shebang
    my string $perl_file_suffix = 'pl';



# NEED FIX: re-enable Perl file suffix selection below
# NEED FIX: re-enable Perl file suffix selection below
# NEED FIX: re-enable Perl file suffix selection below

#    if((defined $self->{python_preparsed}) and 
#       (defined $self->{python_preparsed}->[0]) and 
#        ($self->{python_preparsed}->[0]->isa('Python::Shebang'))) {
#        $perl_file_suffix = 'pl';
#    }
#    else {
#        $perl_file_suffix = 'pm';
#    }



    # for simple 'FOO.py' file names, simply replace with 'FOO.p(l|m)'
    if ($python_file_name =~ m/\.py$/) {
        substr $perl_file_name, -2, 2, $perl_file_suffix;
    }
    # for various 'FOO.pyX' file names, emit warning and replace with 'FOO.pyX.p(l|m)'
    elsif ($python_file_name =~ m/\.py[0-9a-zA-Z]*$/) {

# NEED UPGRADE: handle Pyrex 'FOO.pyx' file names
# NEED UPGRADE: handle Pyrex 'FOO.pyx' file names
# NEED UPGRADE: handle Pyrex 'FOO.pyx' file names

#        $perl_file_name =~ s/\.py[0-9a-zA-Z]*$/\.pl/gmsx;  # rename FOO.pyX to FOO.pl
        $perl_file_name = $python_file_name . '.' . $perl_file_suffix;  # rename FOO.pyX to FOO.pyX.p(l|m)
        carp 'WARNING WPYFI045a: received special Python file name \'', $python_file_name, '\', renaming to standard Perl file name \'', $perl_file_name, '\', carping';
    }
    # for unrecognized 'FOO.BAR' file names, emit warning and replace with 'FOO.BAR.p(l|m)'
    else {
        $perl_file_name = $python_file_name . '.' . $perl_file_suffix;
        carp 'WARNING WPYFI045b: received unrecognized file name \'', $python_file_name, '\', renaming to appended Perl file name \'', $perl_file_name, '\', carping';
    }

    # NEED FIX: accept and utilize Perl directory
    $self->{perl_file_path} = File::Spec->catpath($python_volume, $python_directory, $perl_file_name );
print 'in python_file_path_to_perl_file_path(), about to return $self->{perl_file_path} = \'', $self->{perl_file_path}, '\'', "\n";

    return $self->{perl_file_path};
}


# PYFI03x
sub python_preparsed_to_perl_source {
# return Perl source code
    { my string $RETURN_TYPE };
    ( my Python::File $self, my OpenAI::API $openai ) = @ARG;

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYFI030: undefined OpenAI API, croaking';
    }

    # DEV NOTE, PYFI031: $self->{python_source_code} not used in this translation, no need to error check

    # error or warning if no pre-parsed components
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
        croak 'ERROR EPYFI032: non-existent or undefined Python pre-parsed components, croaking';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYFI032: empty Python pre-parsed components, carping';
    }

    # initialize property that will store de-parsed & translated source code;
    # save fully translated Perl source code, to avoid repeated translating
    $self->{perl_source_code_full} = '';

    # de-parse & translate file contents
    foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed}}) {
#print 'in Python::File->python_preparsed_to_perl_source(), file \'', $self->{python_file_path}, '\', de-parsing & translating file contents, about to call python_preparsed_to_perl_source()...', "\n";
        $self->{perl_source_code_full} .= $python_preparsed_component->python_preparsed_to_perl_source($openai) . "\n";
#print 'in Python::File->python_preparsed_to_perl_source(), file \'', $self->{python_file_path}, '\', de-parsing & translating file contents, ret from call python_preparsed_to_perl_source()', "\n";
    }

    # remove extra trailing newline, to match original input source code
    chomp $self->{perl_source_code_full};

    # return de-parsed & translated Perl source code
    return $self->{perl_source_code_full};
}


# PYFI02x
sub python_preparsed_to_python_source {
# return Python source code
    { my string $RETURN_TYPE };
    ( my Python::File $self ) = @ARG;

    # DEV NOTE, PYFI020: $openai not used in Python-to-Python de-parse round-tripping, no need to error check

# DEV NOTE: in Python::File objects, the python_source_code property contains the original source code read from the Python input file,
# not the pre-parsed Python source code which can be found in the python_source_code property of other Python::Component classes,
# so the python_source_code property is not used as part of the de-parse process and thus does not need to be error-checked here
#    if ((not exists  $self->{python_source_code}) or
#        (not defined $self->{python_source_code})) {
#        croak 'ERROR EPYFI021: non-existent or undefined Python source code, croaking';
#    }
#    elsif ($self->{python_source_code} eq '') {
#        carp 'WARNING WPYFI021: empty Python source code, carping';
#    }

    # error or warning if no pre-parsed components
    if ((not exists  $self->{python_preparsed}) or
        (not defined $self->{python_preparsed})) {
        croak 'ERROR EPYFI022: non-existent or undefined Python pre-parsed components, croaking';
    }
    elsif ((scalar @{$self->{python_preparsed}}) == 0) {
        carp 'WARNING WPYFI022: empty Python pre-parsed components, carping';
    }

    # initialize property that will store de-parsed source code;
    # save fully de-parsed Python source code, to avoid repeated de-parsing
    $self->{python_source_code_full} = '';

    # de-parse file contents
    foreach my Python::Component $python_preparsed_component (@{$self->{python_preparsed}}) {
#print 'in Python::File->python_preparsed_to_python_source(), file \'', $self->{python_file_path}, '\', de-parsing file contents, about to call python_preparsed_to_python_source()...', "\n";
        $self->{python_source_code_full} .= $python_preparsed_component->python_preparsed_to_python_source() . "\n";
#print 'in Python::File->python_preparsed_to_python_source(), file \'', $self->{python_file_path}, '\', de-parsing file contents, ret from call python_preparsed_to_python_source()', "\n";
    }

    # remove extra trailing newline, to match original input source code
    chomp $self->{python_source_code_full};

    # return de-parsed Python source code
    return $self->{python_source_code_full};
}


# PYFI01x
sub python_last_active_character_find {
# select last active (non-comment, non-whitespace) character
    { my character $RETURN_TYPE };
    (   my Python::File $self,
        my character $python_last_active_character,
        my string $python_last_active_characters,
    ) = @ARG;
print 'in python_last_active_character_find(), received $python_last_active_character = \'', ((defined $python_last_active_character) ? $python_last_active_character : '<undef>'), '\'', "\n";
print 'in python_last_active_character_find(), received $python_last_active_characters = \'', $python_last_active_characters, '\'', "\n";

    # match last non-whitespace (\S) non-comment (\#.*) character in the string
    $python_last_active_characters =~ m/(\S)\s*(\#.*)?$/;

    if ((defined $1) and ($1 ne q{})) {
        $python_last_active_character = $1;
print 'in python_last_active_character_find(), YES actually updating $python_last_active_character = \'', $python_last_active_character, '\'', "\n";
    }
    else {
print 'in python_last_active_character_find(), NOT actually updating $python_last_active_character = \'', $python_last_active_character, '\'', "\n";
        carp 'WARNING WPYFI010: no active character found in source code where one was expected, carping';
    }

print 'in python_last_active_character_find(), about to return $python_last_active_character = \'', $python_last_active_character, '\'', "\n";
    return $python_last_active_character;
}


# PYFI00x
sub python_file_to_python_preparsed {
# pre-parse a file of Python source code into Perl data structures
    { my Python::Component::arrayref $RETURN_TYPE };
    (   my Python::File $self,
        my Python::Include::hashref $python_includes,
        my Python::Function::hashref $python_functions,
        my Python::Class::hashref $python_classes
    ) = @ARG;
print 'in python_file_to_python_preparsed(), received $self->{python_file_path} = \'', $self->{python_file_path}, '\'', "\n";

    # open Python source code file for reading
    open (my filehandleref $PYTHON_FILE, '<', $self->{python_file_path})
        or croak 'ERROR EPYFI000a: failed to open Python source code file \'', $self->{python_file_path}, 
            '\' for reading, received OS error message \'', $OS_ERROR, '\', croaking';  # DEV NOTE: $OS_ERROR == $!

    # initialize primary python_preparsed data structure to empty array, will be populated with Python::Component objects
    $self->{python_preparsed} = [];

    # initialize property that will store input source code
    $self->{python_source_code} = '';

    # the changing target for where each new pre-parsed component should be stored, based on the nesting of namespaces;
    # default value is the primary python_preparsed data structure
    my hashref::arrayref $python_preparsed_target = $self->{python_preparsed};  

    # initialize variables used to track components of this Python source code file
    my hashref $python_component = undef;  # Python component represented as Perl hash data structure, to be blessed into Perl class
    my integer $python_line_number = 0;  # current line number
    my string $python_namespace_name = undef;  # fully scoped name of namespace (function or class) currently being parsed
    my Python::Component::arrayref $python_namespaces = [];  # namespace stack AKA the scope, all namespaces enclosing current line of code
    my character $python_last_active_character = undef;  # the last non-whitespace non-comment character, for look-back

    # loop through each line of the Python source code file;
    # read all file contents into variable in memory and check for includes, functions, and classes;
    while (<$PYTHON_FILE>) {
        $self->{python_source_code} .= $ARG;  # DEV NOTE: $ARG == $_
        $python_line_number++;
print 'in python_file_to_python_preparsed(), input line #', $python_line_number, ', have champ($ARG) = \'', champ($ARG), '\'', "\n";
print 'in python_file_to_python_preparsed(), input line #', $python_line_number, ', have $python_last_active_character = \'', ((defined $python_last_active_character) ? $python_last_active_character : '<undef>'), '\'', "\n";

        # check for shebang on first line only
        if (($python_line_number == 1) and ($ARG =~ m/^#!.*python.*$/)) {
print 'in python_file_to_python_preparsed(), Python shebang detected', "\n";
            # create new component
            push @{$python_preparsed_target},
            Python::Shebang->new(
            {
                component_type => 'Python::Shebang',
                python_line_number_begin => $python_line_number,
                python_line_number_end => $python_line_number,
                python_source_code => $ARG,
            });
            next;
        }

        # pre-parse & skip everything inside multi-line '''comment''', except for closing quotes
        if (((scalar @{$python_preparsed_target}) > 0) and
            $python_preparsed_target->[-1]->isa('Python::CommentSingleQuotes') and 
           ($python_preparsed_target->[-1]->{python_line_number_end} < 0)) {
print 'in python_file_to_python_preparsed(), inside multi-line single-quotes \'\'\'comment\'\'\'', "\n";
            # accumulate current (possibly last) Python line of multi-line component
            chomp $ARG;
            $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;

            if ($ARG =~ m/^(.*)\'\'\'\s*$/) {
                # accumulate last Perl line of multi-line component;
                # comments are translated during pre-parse phase, save translated Perl source code component after Python component ends;

                if ($python_preparsed_target->[-1]->{is_actually_string_literal}) {
print 'in python_file_to_python_preparsed(), ending multi-line single-quotes \'\'\'string literal\'\'\'', "\n";

                    # convert Comment object to Unknown object, because this is actually a string literal not a comment

                    # DEV NOTE, CORRELATION PYFI102: all Unknown logic in this if-elsif-else block must be copied
                    # check if previous component was Unknown
                    if (((scalar @{$python_preparsed_target}) > 1) and
                        $python_preparsed_target->[-2]->isa('Python::Unknown')) {
print 'in python_file_to_python_preparsed(), have previous UNKNOWN line, accumulating', "\n";
                        # accumulate multiple single-line components into a multi-line component
                        $python_preparsed_target->[-2]->{python_source_code} .= 
                            "\n" . $python_preparsed_target->[-1]->{python_source_code};
                        # update ending line number
                        $python_preparsed_target->[-2]->{python_line_number_end} = $python_line_number;
                        # discard now-redundant String Literal components
                        pop @{$python_preparsed_target};
                    }
                    elsif (((scalar @{$python_preparsed_target}) > 2) and
                        $python_preparsed_target->[-2]->isa('Python::Blank') and
                        $python_preparsed_target->[-3]->isa('Python::Unknown')) {
print 'in python_file_to_python_preparsed(), have previous UNKNOWN line preceded by blank line(s) and other UNKNOWN line(s), merging components', "\n";

                        # merge 3 components into a single component;
                        # Unknown + Blank + String Literal = Unknown
                        $python_preparsed_target->[-3]->{python_source_code} .=
                            "\n" . $python_preparsed_target->[-2]->{python_source_code} . 
                            "\n" . $python_preparsed_target->[-1]->{python_source_code};
                        # update ending line number
                        $python_preparsed_target->[-3]->{python_line_number_end} = $python_line_number;
                        # discard now-redundant Blank and String Literal components
                        pop @{$python_preparsed_target};
                        pop @{$python_preparsed_target};
                    }
                    else {
print 'in python_file_to_python_preparsed(), have previous UNKNOWN line, converting', "\n";
                        # discard now-redundant String Literal component,
                        # saving for just long enough to create new Unknown component
                        my Python::Comment $discarded_string_literal = pop @{$python_preparsed_target};
                        # create new component
                        push @{$python_preparsed_target},
                        Python::Unknown->new(
                        {
                            component_type => 'Python::Unknown',
                            python_line_number_begin => $discarded_string_literal->{python_line_number_begin},
                            python_line_number_end => $python_line_number,
                            python_source_code => $discarded_string_literal->{python_source_code},
                            perl_source_code => undef  # unknown code is not translated during pre-parse phase
                        });
                    }

print 'in python_file_to_python_preparsed(), ending multi-line single-quotes \'\'\'string literal\'\'\'', "\n";
#die 'TMP DEBUG, END MULTI-LINE STRING LITERAL SINGLE QUOTES';
                }
                else {
print 'in python_file_to_python_preparsed(), ending multi-line single-quotes \'\'\'comment\'\'\'', "\n";
                    # if ending line contains leading characters (including whitespace),
                    # then append/prepend additional '#' char to ensure leading characters are maintained as comments
                    $python_preparsed_target->[-1]->{perl_source_code} .= "\n";
                    # indentation whitespace only before closing ''', do NOT prepend additional '#' character
                    if ($ARG =~ m/^(\s+)\'\'\'\s*$/) {
                        $python_preparsed_target->[-1]->{perl_source_code} .= $1;
                    }
                    # indentation whitespace and other characters before closing ''',
                    # append additional '#' character to indentation
                    elsif ($ARG =~ m/^(\s+)(.+)\'\'\'\s*$/) {
                        $python_preparsed_target->[-1]->{perl_source_code} .= (substr $1, 0, -1) . '#' . $2;
                    }
                    # non-whitespace characters before closing ''',
                    # prepend additional '#' character by shifting all characters to the right
                    elsif ($ARG =~ m/^(.+)\'\'\'\s*$/) {
                        $python_preparsed_target->[-1]->{perl_source_code} .= '#' . $1;
                    }
                    # else, no characters at all before closing '''
                    $python_preparsed_target->[-1]->{perl_source_code} .= q{#''};

                    # set ending line number, indicating we are no longer inside this multi-line component
                    $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;

print 'in python_file_to_python_preparsed(), ending multi-line single-quotes \'\'\'comment\'\'\', have $python_preparsed_target->[-1]->{perl_source_code} = ', "\n", $python_preparsed_target->[-1]->{perl_source_code}, "\n";
#die 'TMP DEBUG, END MULTI-LINE COMMENT SINGLE QUOTES';
                }

                next;
            }
            elsif ($ARG =~ m/\'\'\'/) {
                croak 'ERROR EPYFI001: have multi-line single-quotes comment closing, but not at end of line, do not know how to handle, croaking';
            }
            elsif ($ARG =~ m/\"\"\"/) {
                carp 'WARNING WPYFI001: have multi-line double-quotes comment while currently inside multi-line single-quotes comment, ignoring, carping';
            }

            # prepend '#' character for non-blank comments,
            # either replacing indentation space or shifting all characters to the right
            my string $comment = $ARG;
            if (($comment eq '') or
                ($python_preparsed_target->[-1]->{is_actually_string_literal}))
            { 1; }
            elsif ($comment =~ m/^(\s+)(.*)$/) { 
                # if indented at least 2 spaces, then we can vertically align all '#' characters
                if (((length $python_preparsed_target->[-1]->{indentation}) >= 2) and
                    ((length $1) >= 2)) {
                    substr $comment, ((length $python_preparsed_target->[-1]->{indentation}) - 2), 1, '#';
                }
                else { $comment = (substr $1, 0, -2) . '# ' . $2; }
            }
            else { $comment = '#' . $comment; }

            # accumulate non-last Perl line of multi-line component; copy comments verbatim
            $python_preparsed_target->[-1]->{perl_source_code} .= "\n" . $comment;

            # did not end multi-line component, go on to next line
            next;
        }
        # pre-parse & skip everything inside multi-line """comment""", except for closing quotes
        elsif (((scalar @{$python_preparsed_target}) > 0) and
               $python_preparsed_target->[-1]->isa('Python::CommentDoubleQuotes') and 
              ($python_preparsed_target->[-1]->{python_line_number_end} < 0)) {
print 'in python_file_to_python_preparsed(), inside multi-line double-quotes \"\"\"comment\"\"\"', "\n";
            # accumulate current (possibly last) Python line of multi-line component
            chomp $ARG;
            $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;

            if ($ARG =~ m/^(.*)\"\"\"\s*$/) {
print 'in python_file_to_python_preparsed(), ending multi-line double-quotes \"\"\"comment\"\"\"', "\n";
                # accumulate last Perl line of multi-line component;
                # comments are translated during pre-parse phase, save translated Perl source code component after Python component ends;



                if ($python_preparsed_target->[-1]->{is_actually_string_literal}) {
print 'in python_file_to_python_preparsed(), ending multi-line double-quotes \"\"\"string literal\"\"\"', "\n";

                    # convert Comment object to Unknown object, because this is actually a string literal not a comment

                    # DEV NOTE, CORRELATION PYFI102: all Unknown logic in this if-elsif-else block must be copied
                    # check if previous component was Unknown
                    if (((scalar @{$python_preparsed_target}) > 1) and
                        $python_preparsed_target->[-2]->isa('Python::Unknown')) {
print 'in python_file_to_python_preparsed(), have previous UNKNOWN line, accumulating', "\n";
                        # accumulate multiple single-line components into a multi-line component
                        $python_preparsed_target->[-2]->{python_source_code} .= 
                            "\n" . $python_preparsed_target->[-1]->{python_source_code};
                        # update ending line number
                        $python_preparsed_target->[-2]->{python_line_number_end} = $python_line_number;
                        # discard now-redundant String Literal components
                        pop @{$python_preparsed_target};
                    }
                    elsif (((scalar @{$python_preparsed_target}) > 2) and
                        $python_preparsed_target->[-2]->isa('Python::Blank') and
                        $python_preparsed_target->[-3]->isa('Python::Unknown')) {
print 'in python_file_to_python_preparsed(), have previous UNKNOWN line preceded by blank line(s) and other UNKNOWN line(s), merging components', "\n";

                        # merge 3 components into a single component;
                        # Unknown + Blank + String Literal = Unknown
                        $python_preparsed_target->[-3]->{python_source_code} .=
                            "\n" . $python_preparsed_target->[-2]->{python_source_code} . 
                            "\n" . $python_preparsed_target->[-1]->{python_source_code};
                        # update ending line number
                        $python_preparsed_target->[-3]->{python_line_number_end} = $python_line_number;
                        # discard now-redundant Blank and String Literal components
                        pop @{$python_preparsed_target};
                        pop @{$python_preparsed_target};
                    }
                    else {
print 'in python_file_to_python_preparsed(), have previous UNKNOWN line, converting', "\n";
                        # discard now-redundant String Literal component,
                        # saving for just long enough to create new Unknown component
                        my Python::Comment $discarded_string_literal = pop @{$python_preparsed_target};
                        # create new component
                        push @{$python_preparsed_target},
                        Python::Unknown->new(
                        {
                            component_type => 'Python::Unknown',
                            python_line_number_begin => $discarded_string_literal->{python_line_number_begin},
                            python_line_number_end => $python_line_number,
                            python_source_code => $discarded_string_literal->{python_source_code},
                            perl_source_code => undef  # unknown code is not translated during pre-parse phase
                        });
                    }

print 'in python_file_to_python_preparsed(), ending multi-line double-quotes \"\"\"string literal\"\"\"', "\n";
#die 'TMP DEBUG, END MULTI-LINE STRING LITERAL SINGLE QUOTES';
                }
                else {
print 'in python_file_to_python_preparsed(), ending multi-line double-quotes \"\"\"comment\"\"\"', "\n";
                    # if ending line contains leading characters (including whitespace),
                    # then append/prepend additional '#' char to ensure leading characters are maintained as comments
                    $python_preparsed_target->[-1]->{perl_source_code} .= "\n";
                    # indentation whitespace only before closing """, do NOT prepend additional '#' character
                    if ($ARG =~ m/^(\s+)\"\"\"\s*$/) {
                        $python_preparsed_target->[-1]->{perl_source_code} .= $1;
                    }
                    # indentation whitespace and other characters before closing """, append additional '#' character to indentation
                    elsif ($ARG =~ m/^(\s+)(.+)\"\"\"\s*$/) {
                        $python_preparsed_target->[-1]->{perl_source_code} .= (substr $1, 0, -1) . '#' . $2;
                    }
                    # non-whitespace characters before closing """, prepend additional '#' character by shifting all characters to the right
                    elsif ($ARG =~ m/^(.+)\"\"\"\s*$/) {
                        $python_preparsed_target->[-1]->{perl_source_code} .= '#' . $1;
                    }
                    # else, no characters at all before closing """
                    $python_preparsed_target->[-1]->{perl_source_code} .= q{#""};

                    # set ending line number, indicating we are no longer inside this multi-line component
                    $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;

print 'in python_file_to_python_preparsed(), ending multi-line double-quotes \"\"\"comment\"\"\", have $python_preparsed_target->[-1]->{perl_source_code} = ', "\n", $python_preparsed_target->[-1]->{perl_source_code}, "\n";
#die 'TMP DEBUG, MULTI-LINE COMMENT DOUBLE QUOTES';
                }

                next;
            }
            elsif ($ARG =~ m/\"\"\"/) {
                croak 'ERROR EPYFI002: have multi-line double-quotes comment closing, but not at end of line, do not know how to handle, croaking';
            }
            elsif ($ARG =~ m/\'\'\'/) {
                carp 'WARNING WPYFI002: have multi-line single-quotes comment while currently inside multi-line double-quotes comment, ignoring, carping';
            }

            # prepend '#' character for non-blank comments,
            # either replacing last indentation space or shifting all characters to the right
            my string $comment = $ARG;
            if (($comment eq '') or
                ($python_preparsed_target->[-1]->{is_actually_string_literal}))
            { 1; }
            elsif ($comment =~ m/^(\s+)(.*)$/) { 
                # if indented at least 2 spaces, then we can vertically align all '#' characters
                if (((length $python_preparsed_target->[-1]->{indentation}) >= 2) and
                    ((length $1) >= 2)) {
                    substr $comment, ((length $python_preparsed_target->[-1]->{indentation}) - 2), 1, '#';
                }
                else { $comment = (substr $1, 0, -2) . '# ' . $2; }
            }
            else { $comment = '#' . $comment; }

            # accumulate non-last Perl line of multi-line component; copy comments verbatim
            $python_preparsed_target->[-1]->{perl_source_code} .= "\n" . $comment;

            # did not end multi-line component, go on to next line
            next;
        }
        # pre-parse & accumulate everything inside multi-line include statement
        elsif (((scalar @{$python_preparsed_target}) > 0) and
               $python_preparsed_target->[-1]->isa('Python::Include') and 
              ($python_preparsed_target->[-1]->{python_line_number_end} < 0)) {
print 'in python_file_to_python_preparsed(), inside multi-line include', "\n";
            # accumulate current (possibly last) Python line of multi-line component
            chomp $ARG;
            $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # multi-line includes with parentheses end differently than those without parentheses
            if ($python_preparsed_target->[-1]->{python_has_parentheses}) {
                # end multi-line include (w/ parentheses) when the last non-whitespace non-comment character is a close parentheses
                if ($ARG =~ m/^.*\)\s*(?:\#.*)?$/) {
print 'in python_file_to_python_preparsed(), ending multi-line include w/ parentheses', "\n";
                    # set ending line number, indicating we are no longer inside this multi-line component
                    $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;

                    next;
                }
            }
            else {
                # end multi-line include (w/out parentheses) when the last non-whitespace character is not a backslash
#                if ($ARG =~ m/^.*[^\\]\s*$/) {  # does not match correctly?
                if ($ARG !~ m/^.*\\\s*$/) {
print 'in python_file_to_python_preparsed(), ending multi-line include w/out parentheses', "\n";
                    # set ending line number, indicating we are no longer inside this multi-line component
                    $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;

                    next;
                }
            }

            # error if multi-line component invalidly nested inside other multi-line component
            if ($ARG =~ m/\'\'\'/) {
                croak 'ERROR EPYFI003a: have multi-line single-quotes comment while currently inside multi-line include statement, do not know how to handle, croaking';
            }
            elsif ($ARG =~ m/\"\"\"/) {
                croak 'ERROR EPYFI003b: have multi-line double-quotes comment while currently inside multi-line include statement, do not know how to handle, croaking';
            }

            # did not end multi-line component, go on to next line
            next;
        }
        # pre-parse & accumulate everything inside multi-line function header
        elsif (((scalar @{$python_preparsed_target}) > 0) and
               $python_preparsed_target->[-1]->isa('Python::Function') and 
              ($python_preparsed_target->[-1]->{python_line_number_end_header} < 0)) {
print 'in python_file_to_python_preparsed(), inside multi-line function header', "\n";
            # accumulate current (possibly last) Python line of multi-line component
            chomp $ARG;
            $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # end multi-line function header when it matches the entire regex;

            # DEV NOTE, CORRELATION PYFI100: all regex changes must be reflected in both locations,
            # the only difference should be the optional trailing comment pattern \s*(?:\#.*\n)?\s*
            # which is not in the header-opening regex and is used twice in the header-closing regex;
            # DEV NOTE: do NOT join multiple lines into one line for regex match,
            # need \n characters to detect trailing comments,
            # \s matches \n so multiple lines do not need to be combined
                #  $1         $2           $3                                                                                                                                                                                                                                                                                                        $4                             $5    $6
            if (# Python
                ($python_preparsed_target->[-1]->{python_source_code} =~
                m/^(\s*)def\s+(\w+)\s*\(\s*((?:[\w\.\*]+\s*(?::\s*[\w\.]+\s*)?(?:\[.*\]\s*)?(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,\s*(?:\#.*\n)?\s*)*[\w\.\*]+\s*(?::\s*[\w\.]+\s*)?(?:\[.*\]\s*)?(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,?\s*(?:\#.*\n)?)?\s*\)\s*(?:->\s*([\w\.]+\s*(?:\[.*\]\s*)?))?\s*(:)\s*(\#.*)?$/) or
# NEED ANSWER: does Pyrex accept both C and Python types?  if so, update Pyrex regex below to accept ':str' Python types
# NEED ANSWER: does Pyrex accept both C and Python types?  if so, update Pyrex regex below to accept ':str' Python types
# NEED ANSWER: does Pyrex accept both C and Python types?  if so, update Pyrex regex below to accept ':str' Python types
                # Pyrex
                ($python_preparsed_target->[-1]->{python_source_code} =~
                m/^(\s*)def\s+(\w+)\s*\(\s*((?:(?:(?:const\s+)?(?:[\w\.]+\s*(?:\[[\:\d\,\s]+\])?\s+))?[\w\.\*]+(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,\s*(?:\#.*\n)?\s*)*(?:(?:const\s+)?(?:[\w\.]+\s*(?:\[[\:\d\,\s]+\])?\s+))?[\w\.\*]+(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,?\s*(?:\#.*\n)?)?\s*\)\s*(?:->\s*([\w\.]+))?\s*(:)\s*(\#.*)?$/)) {




print 'in python_file_to_python_preparsed(), ending multi-line function header', "\n";

                # all function header sub-components have been received, so accept them all
                if (defined $3) { $python_preparsed_target->[-1]->{arguments} = $3; }
                if (defined $4) { $python_preparsed_target->[-1]->{return_type} = $4; }

                # set ending line number, indicating we are no longer inside this multi-line component
                $python_preparsed_target->[-1]->{python_line_number_end_header} = $python_line_number;

print 'in python_file_to_python_preparsed(), ending multi-line function header, have $python_preparsed_target->[-1] = ', Dumper($python_preparsed_target->[-1]), "\n";
#die 'TMP DEBUG, END MULTI-LINE FUNCTION HEADER' if ($python_preparsed_target->[-1]->{symbol} eq '__init__');

                next;
            }

            # did not end multi-line component, go on to next line
            next;
        }
        # pre-parse & accumulate everything inside multi-line class header
        elsif (((scalar @{$python_preparsed_target}) > 0) and
               $python_preparsed_target->[-1]->isa('Python::Class') and 
              ($python_preparsed_target->[-1]->{python_line_number_end_header} < 0)) {
print 'in python_file_to_python_preparsed(), inside multi-line class header', "\n";
            # accumulate current (possibly last) Python line of multi-line component
            chomp $ARG;
            $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # end multi-line class header when it matches the entire regex;

            # DEV NOTE, CORRELATION PYFI101: all regex changes must be reflected in both locations,
            # the only difference should be the optional trailing comment pattern \s*(?:\#.*\n)?\s*
            # which is not in the header-opening regex and is used twice in the header-closing regex;
            # DEV NOTE: do NOT join multiple lines into one line for regex match,
            # need \n characters to detect trailing comments,
            # \s matches \n so multiple lines do not need to be combined
            if (# Python
                ($python_preparsed_target->[-1]->{python_source_code} =~ 
                #  $1           $2              $3                                                                          $4    $5
                m/^(\s*)class\s+(\w+)\s*(?:\(\s*((?:[\w\.=]+\s*\,\s*(?:\#.*\n)?\s*)*[\w\.=]+\s*\,?\s*(?:\#.*\n)?)?\s*\)\s*)?(:)\s*(\#.*)?$/) or
                # Pyrex
                ($python_preparsed_target->[-1]->{python_source_code} =~ 
                m/^(\s*)cdef\s+class\s+(\w+)(?:\{\{\w+\}\})?\s*(?:\(\s*((?:[\w\.=]+(?:\{\{\w+\}\})?[\w\.=]*\s*\,\s*(?:\#.*\n)?\s*)*[\w\.=]+(?:\{\{\w+\}\})?[\w\.=]*\s*\,?\s*(?:\#.*\n)?)?\s*\)\s*)?(:)\s*(\#.*)?$/)) {
print 'in python_file_to_python_preparsed(), ending multi-line class header', "\n";

                # all class header sub-components have been received, so accept them all
                if (defined $3) { $python_preparsed_target->[-1]->{parents} = $3; }

                # set ending line number, indicating we are no longer inside this multi-line component
                $python_preparsed_target->[-1]->{python_line_number_end_header} = $python_line_number;

print 'in python_file_to_python_preparsed(), ending multi-line class header, have $python_preparsed_target->[-1] = ', Dumper($python_preparsed_target->[-1]), "\n";
#die 'TMP DEBUG, END MULTI-LINE CLASS HEADER' if ($python_preparsed_target->[-1]->{symbol} eq '__init__');

                next;
            }

            # did not end multi-line component, go on to next line
            next;
        }

        # DEV NOTE: multi-line classes & functions can contain multi-line comments & includes, so break elsif() and start new if();
        # pre-parse & accumulate everything inside multi-line namespaces (functions & classes)
        if ((scalar @{$python_namespaces}) > 0) {
print 'in python_file_to_python_preparsed(), inside multi-line namespace', "\n";
#print 'in python_file_to_python_preparsed(), have all outer namespaces $python_namespaces = ', Dumper($python_namespaces), "\n";
#print 'in python_file_to_python_preparsed(), have next outer namespace $python_namespaces->[-1] = ', Dumper($python_namespaces->[-1]), "\n";
print 'in python_file_to_python_preparsed(), have next outer namespace $python_namespaces->[-1]->{symbol_scoped} = \'', $python_namespaces->[-1]->{symbol_scoped}, '\'', "\n";

            # end multi-line namespace(s) when the indentation level returns to the same as, or less than, the first line of its definition,
            # not counting blank (empty) lines or whitespace-only lines
            $ARG =~ m/^(\s*)[^\s]/;

print 'in python_file_to_python_preparsed(), have current line leading whitespace $1 = \'', (defined($1) ? $1 : '<<<undef>>>'), '\'', "\n";
print 'in python_file_to_python_preparsed(), have next outer namespace $python_namespaces->[-1]->{indentation} = \'', $python_namespaces->[-1]->{indentation}, '\'', "\n";

            # if regex above does not match, then $1 will be undefined;
            # this can only happen with blank (empty) lines and whitespace-only lines
            if ((defined $1) and
                ((length $1) <= (length $python_namespaces->[-1]->{indentation}))) {
print 'in python_file_to_python_preparsed(), ending one or more multi-line namespaces', "\n";

                # continue removing namespaces from the stack, as long as the stack is not empty and the indentation level is less or equal
                while (((scalar @{$python_namespaces}) > 0) and
                       ((length $1) <= (length $python_namespaces->[-1]->{indentation}))) {
print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\'', "\n";

                    # DEV NOTE: namespaces do not end with blank lines; 
                    # move all blank lines to end of next-higher namespace if there are any more, 
                    # or to $self->{python_preparsed} if this is the last namespace on the stack;
                    # if this is not the last namespace on the stack, then blank line(s) remain in the last active namespace
                    my Python::Component::arrayref $independent_blank_lines = [];
                    while (((scalar @{$python_namespaces->[-1]->{python_preparsed}}) > 0) and
                        $python_namespaces->[-1]->{python_preparsed}->[-1]->isa('Python::Blank')) {
                        unshift(@{$independent_blank_lines}, pop(@{$python_namespaces->[-1]->{python_preparsed}}));
print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\', popped off independent blank line = ', Dumper($independent_blank_lines->[0]), "\n";
                    }

print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\', have $independent_blank_lines = ', Dumper($independent_blank_lines), "\n";

                    if ((scalar @{$python_namespaces}) > 1) {
                        push @{$python_namespaces->[-2]->{python_preparsed}}, @{$independent_blank_lines};
print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\', pushed independent blank lines onto next-higher namespace = \'', $python_namespaces->[-2]->{symbol_scoped}, '\'', "\n";
                    }
                    else {
                        push @{$self->{python_preparsed}}, @{$independent_blank_lines};
print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\', pushed independent blank lines onto top-level $self->{python_preparsed}', "\n";
                    }

                    # set ending line number, indicating we are no longer inside this multi-line component;
                    # we are currently on a new line outside the component,
                    # so the multi-line component actually ended on the previous line number if no independent blank lines were moved,
                    # otherwise the multi-line component actually ended on the line before the first blank line started
                    if ((scalar @{$independent_blank_lines}) == 0) {
                        $python_namespaces->[-1]->{python_line_number_end} = $python_line_number - 1;
print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\', no independent blank lines found so namespace ended on previous line = ', $python_namespaces->[-1]->{python_line_number_end}, "\n";
                    }
                    else {
                        $python_namespaces->[-1]->{python_line_number_end} = $independent_blank_lines->[0]->{python_line_number_begin} - 1;
print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\', yes independent blank lines found so namespace ended on line before first blank line started = ', $python_namespaces->[-1]->{python_line_number_end}, "\n";
                    }

                    pop @{$python_namespaces};
                }

                # update name of current namespace
                if ((scalar @{$python_namespaces}) > 0) {
                    $python_namespace_name = $python_namespaces->[-1]->{symbol_scoped};
                }
                else {
                    $python_namespace_name = undef;
                }

                # do not skip to next line, continue pre-parsing as-yet-unidentified current line of Python source code in $ARG
            }
        }

        # DEV NOTE: if namespace (function or class) is ended above,
        # then code is not accumulated and not yet pre-parsed, so use if() not elsif()

        # determine correct location to push preparsed components;
        if ((scalar @{$python_namespaces}) > 0) {
            # if we are inside an enclosing namespace, always push preparsed components into that namespace's object;
            # the enclosing component is the last item in the namespace stack
            $python_preparsed_target = $python_namespaces->[-1]->{python_preparsed};
        }
        else {
            # otherwise we are outside all namespaces, so we push preparsed components into the primary base-level data structure
            $python_preparsed_target = $self->{python_preparsed};
        }

        # NEED ANSWER: can multi-line includes really include blank (empty) lines?
        # pre-parse & skip blank (empty) lines; must check after multi-line components, which may contain their own blank (empty) lines
        if ($ARG =~ m/^$/) {
print 'in python_file_to_python_preparsed(), have blank (empty) line', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # check if previous component was same type
            if (((scalar @{$python_preparsed_target}) > 0) and
                $python_preparsed_target->[-1]->isa('Python::Blank')) {
print 'in python_file_to_python_preparsed(), have blank (empty) line, accumulating', "\n";
                # accumulate multiple single-line components into a multi-line component
                $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;  # update ending line number
                $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;
                $python_preparsed_target->[-1]->{perl_source_code} .= "\n" . $ARG;  # copy blank (empty) lines verbatim
            }
            else {
print 'in python_file_to_python_preparsed(), have blank (empty) line, creating', "\n";
                # create new component
                push @{$python_preparsed_target},
                Python::Blank->new(
                {
                    component_type => 'Python::Blank',
                    python_line_number_begin => $python_line_number,
                    python_line_number_end => $python_line_number,
                    python_source_code => $ARG,
                    perl_source_code => $ARG  # copy blank (empty) lines verbatim
                });
            }

            next;
        }
        # NEED ANSWER: can multi-line includes really include whitespace lines?
        # pre-parse & skip whitespace lines; must check after multi-line components, which may contain their own whitespace lines
        elsif ($ARG =~ m/^\s+$/) {
print 'in python_file_to_python_preparsed(), have whitespace line', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # check if previous component was same type
            if (((scalar @{$python_preparsed_target}) > 0) and
                $python_preparsed_target->[-1]->isa('Python::Whitespace')) {
print 'in python_file_to_python_preparsed(), have whitespace line, accumulating', "\n";
                # accumulate multiple single-line components into a multi-line component
                $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;  # update ending line number
                $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;
                $python_preparsed_target->[-1]->{perl_source_code} .= "\n" . $ARG;  # copy whitespace lines verbatim
            }
            else {
print 'in python_file_to_python_preparsed(), have whitespace line, creating', "\n";
                # create new component
                push @{$python_preparsed_target},
                Python::Whitespace->new(
                {
                    component_type => 'Python::Whitespace',
                    python_line_number_begin => $python_line_number,
                    python_line_number_end => $python_line_number,
                    python_source_code => $ARG,
                    perl_source_code => $ARG  # copy whitespace lines verbatim
                });
            }

            next;
        }
        # pre-parse & skip single-line # comments
        elsif ($ARG =~ m/^\s*\#/) {
print 'in python_file_to_python_preparsed(), have single-line # comment', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # check if previous component was same type
            if (((scalar @{$python_preparsed_target}) > 0) and
                $python_preparsed_target->[-1]->isa('Python::Comment')) {
print 'in python_file_to_python_preparsed(), have single-line # comment, accumulating', "\n";
                # accumulate multiple single-line components into a multi-line component
                $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;  # update ending line number
                $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;
                $python_preparsed_target->[-1]->{perl_source_code} .= "\n" . $ARG;  # copy comments verbatim
            }
            else {
print 'in python_file_to_python_preparsed(), have single-line # comment, creating', "\n";
                # create new component
                push @{$python_preparsed_target},
                Python::Comment->new(
                {
                    component_type => 'Python::Comment',
                    python_line_number_begin => $python_line_number,
                    python_line_number_end => $python_line_number,
                    python_source_code => $ARG,
                    perl_source_code => $ARG  # copy comments verbatim
                });
            }

            next;
        }

# NEED ANSWER: other than left parentheses and comma, what other characters indicate non-void context???
# NEED ANSWER: other than left parentheses and comma, what other characters indicate non-void context???
# NEED ANSWER: other than left parentheses and comma, what other characters indicate non-void context???

        # pre-parse & skip single-line '''comments''';
        # DEV NOTE: if last active character is left parentheses or comma,
        # then context is not void and this is not a comment
        elsif (($ARG =~ m/^(\s*)\'\'\'(.*)\'\'\'\s*$/) and
               ($python_last_active_character ne '(') and
               ($python_last_active_character ne ',')) {
print 'in python_file_to_python_preparsed(), have single-line \'\'\'comment\'\'\'', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # check if previous component was same type
            if (((scalar @{$python_preparsed_target}) > 0) and
                $python_preparsed_target->[-1]->isa('Python::CommentSingleQuotes')) {
print 'in python_file_to_python_preparsed(), have single-line \'\'\'comment\'\'\', accumulating', "\n";
                # accumulate multiple single-line components into a multi-line component
                $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;  # update ending line number
                $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;
                $python_preparsed_target->[-1]->{perl_source_code} .= "\n" . ($1 . '#  ' . $2);  # reformat comments & retain spacing
            }
            else {
print 'in python_file_to_python_preparsed(), have single-line \'\'\'comment\'\'\', creating', "\n";
                # create new component
                push @{$python_preparsed_target},
                Python::CommentSingleQuotes->new(
                {
                    component_type => 'Python::CommentSingleQuotes',
                    python_line_number_begin => $python_line_number,
                    python_line_number_end => $python_line_number,
                    python_source_code => $ARG,
                    perl_source_code => ($1 . '#  ' . $2)  # reformat comments & retain spacing
                });
            }

            next;
        }
        # pre-parse & skip single-line """comments""";
        # DEV NOTE: if last active character is left parentheses or comma,
        # then context is not void and this is not a comment
        elsif (($ARG =~ m/^(\s*)\"\"\"(.*)\"\"\"\s*$/) and
               ($python_last_active_character ne '(') and
               ($python_last_active_character ne ',')) {
print 'in python_file_to_python_preparsed(), have single-line \"\"\"comment\"\"\"', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # check if previous component was same type
            if (((scalar @{$python_preparsed_target}) > 0) and
                $python_preparsed_target->[-1]->isa('Python::CommentDoubleQuotes')) {
print 'in python_file_to_python_preparsed(), have single-line \"\"\"comment\"\"\", accumulating', "\n";
                # accumulate multiple single-line components into a multi-line component
                $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;  # update ending line number
                $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;
                $python_preparsed_target->[-1]->{perl_source_code} .= "\n" . ($1 . '#  ' . $2);  # reformat comments & retain spacing
            }
            else {
print 'in python_file_to_python_preparsed(), have single-line \"\"\"comment\"\"\", creating', "\n";
                # create new component
                push @{$python_preparsed_target},
                Python::CommentDoubleQuotes->new(
                {
                    component_type => 'Python::CommentDoubleQuotes',
                    python_line_number_begin => $python_line_number,
                    python_line_number_end => $python_line_number,
                    python_source_code => $ARG,
                    perl_source_code => ($1 . '#  ' . $2)  # reformat comments & retain spacing
                });
            }

            next;
        }
        # start multi-line '''comments''';
        elsif ($ARG =~ m/^(\s*)\'\'\'(.*)$/) {
            # DEV NOTE: if last active character is left parentheses or comma,
            # then context is not void and this is not a comment
            my boolean $is_actually_string_literal;
            if (($python_last_active_character eq '(') or
                ($python_last_active_character eq ',')) {
print 'in python_file_to_python_preparsed(), have multi-line \'\'\'string literal, starting', "\n";
                $is_actually_string_literal = 1;
            }
            else {
print 'in python_file_to_python_preparsed(), have multi-line \'\'\'comment, starting', "\n";
                $is_actually_string_literal = 0;
            }

            push @{$python_preparsed_target},
            Python::CommentSingleQuotes->new(
            {
                component_type => 'Python::CommentSingleQuotes',
                indentation => $1,
                is_actually_string_literal => $is_actually_string_literal,
                python_line_number_begin => $python_line_number,
                python_line_number_end => -1,  # negative value means we are currently inside multi-line component
                python_source_code => champ($ARG),
#                perl_source_code => champ('=x ' . $1 . $2)  # DEV NOTE: don't use POD for multi-line comments, POD parsers are inconsistent
                perl_source_code => champ($1 . q{#''} . $2)  # reformat comments & retain spacing
            });
            next;
        }
        # start multi-line """comments""";
        # DEV NOTE: if last active character is left parentheses or comma,
        # then context is not void and this is not a comment
        elsif ($ARG =~ m/^(\s*)\"\"\"(.*)$/) {
            # DEV NOTE: if last active character is left parentheses or comma,
            # then context is not void and this is not a comment
            my boolean $is_actually_string_literal;
            if (($python_last_active_character eq '(') or
                ($python_last_active_character eq ',')) {
print 'in python_file_to_python_preparsed(), have multi-line \"\"\"string literal, starting', "\n";
                $is_actually_string_literal = 1;
            }   
            else {
print 'in python_file_to_python_preparsed(), have multi-line \"\"\"comment, starting', "\n";
                $is_actually_string_literal = 0;
            }

            push @{$python_preparsed_target},
            Python::CommentDoubleQuotes->new(
            {
                component_type => 'Python::CommentDoubleQuotes',
                indentation => $1,
                is_actually_string_literal => $is_actually_string_literal,
                python_line_number_begin => $python_line_number,
                python_line_number_end => -1,  # negative value means we are currently inside multi-line component
                python_source_code => champ($ARG),
#                perl_source_code => champ('=x ' . $1 . $2)  # DEV NOTE: don't use POD for multi-line comments, POD parsers are inconsistent
                perl_source_code => champ($1 . q{#""} . $2)  # reformat comments & retain spacing
            });
            next;
        }
        # start multi-line include statements, either with enclosing parentheses,
        # or with long lines ending in backslash AKA line continuation;
        # match any line starting with 'from' and including an open but not close parentheses,
        # or starting with either 'from' or 'import', or 'cimport' for Pyrex, and ending in backslash
        # https://python-reference.readthedocs.io/en/latest/docs/operators/slash.html
        # NEED ANSWER: can the line continuation backslash appear without any preceding whitespace?
        elsif (($ARG =~ m/^\s*from\s+.*(\()[^\)]*$/) or
               ($ARG =~ m/^\s*from\s+.*\\$/) or
               ($ARG =~ m/^\s*c?import\s+.*\\$/)) {
print 'in python_file_to_python_preparsed(), have multi-line include, starting', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            push @{$python_preparsed_target},
            Python::Include->new(
            {
                component_type => 'Python::Include',
                python_file_path => $self->{python_file_path},
                python_line_number_begin => $python_line_number,
                python_line_number_end => -1,  # negative value means we are currently inside multi-line component
                python_source_code => $ARG,
                python_has_parentheses => (defined $1) ? 1 : 0,
                perl_source_code => undef,  # includes are not translated during pre-parse phase
            });
            next;
        }
        # pre-parse single-line include statements;
        # 'import', or 'cimport' for Pyrex, must be followed by open parentheses or whitespace
        elsif ($ARG =~ m/^\s*(from\s+.+\s+)?c?import[\(\s].+$/) {
print 'in python_file_to_python_preparsed(), have single-line include', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            push @{$python_preparsed_target},
            Python::Include->new(
            {
                component_type => 'Python::Include',
                python_file_path => $self->{python_file_path},
                python_line_number_begin => $python_line_number,
                python_line_number_end => $python_line_number,
                python_source_code => $ARG,
                perl_source_code => undef,  # includes are not translated during pre-parse phase
            });

            next;
        }

# NEED UPGRADE: support single-line Python functions; also, decorators on same line as function definition?
# NEED UPGRADE: support single-line Python functions; also, decorators on same line as function definition?
# NEED UPGRADE: support single-line Python functions; also, decorators on same line as function definition?

        # start function definitions
        # DEV NOTE: can have whitespace around commas
        # DEV NOTE: can have whitespace but NOT newline in between function name and open parentheses
        # DEV NOTE: can have whitespace but NOT newline in between close parentheses and colon
        # DEV NOTE: can have trailing comma at the end of function argument list

        # Python function header examples
        # def FOO():
        # def FOO(BAR):
        # def FOO ( BAR, BAT, BAZ, ) :
        # def FOO(BAR, BAT, BAZ) -> FooReturnType:
        # def __FOO__(self, *, BAR=None, var_BAR=1e-9, force_alpha="warn"):
        # def FOO_BAR(code, extra_preargs=[], extra_postargs=[]):
        # def FOO (
        #
        # ) :
        # def __FOO__(
        #     self,
        #     n_clusters=2,
        #     *,
        #     affinity="deprecated",  # TODO(1.4): Remove
        #     metric=None,  # TODO(1.4): Set to "euclidean"
        #     memory=None,
        #     connectivity=None,
        #     compute_full_tree="auto",
        #     linkage="ward",
        #     distance_threshold=None,
        #     compute_distances=False,
        #     damping=0.5,
        #     eps=np.finfo(np.float64).eps,
        #     slice_=(slice(70, 195), slice(78, 172)),
        # ):
        # def FOO(
        #     BAR: BarType, BAT:BatType="howdy", BAX : BaxType = 23 
        # ) -> FooReturnType:
        # def FOO(
        #     BAR: int,
        #     BAT1: Optional [ str ],
        #     BAT2: typing.Optional[str],
        #     BAX: float = 1.0,
        #     BAZ1: Union[int, str],
        #     BAZ2: typing.Union [ int , str ] = 'howdy',
        # ) -> Dict[str, Any]:

        # Pyrex function header examples
        # def FOO(
        #     const cnp.uint8_t[::1] BAR,
        #     object[:] BAT,
        #     cnp.npy_intp [::1] BAX
        # ):
        # def FOO(
        #     const cnp.float64_t[::1] BAR,
        #     const cnp.float64_t[:, ::1] BAT,
        #     const cnp.intp_t[::1] BAX,
        #     BAZ,
        #     cnp.float64_t[::1] QUUX
        # ):
        # def FOO(cnp.intp_t BAR, BAT, cnp.intp_t BAX):

        # DEV NOTE: either match the entire regex for single-line function header,
        # or match only the start of the function header 'def FOO' and 
        # start multi-line component to accumulate source code lines until entire regex can be matched
        # DEV NOTE, CORRELATION PYFI100: all regex changes must be reflected in both locations,
        # the only difference should be the optional trailing comment pattern \s*(?:\#.*\n)?\s*
        # which is not in the header-opening regex and is used twice in the header-closing regex;
        elsif ( # Python
                #           $1         $2           $3                                                                                                                                                                                                                                                                                                        $4                             $5    $6
                ($ARG =~ m/^(\s*)def\s+(\w+)\s*\(\s*((?:[\w\.\*]+\s*(?::\s*[\w\.]+\s*)?(?:\[.*\]\s*)?(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,\s*(?:\#.*\n)?\s*)*[\w\.\*]+\s*(?::\s*[\w\.]+\s*)?(?:\[.*\]\s*)?(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,?\s*(?:\#.*\n)?)?\s*\)\s*(?:->\s*([\w\.]+\s*(?:\[.*\]\s*)?))?\s*(:)\s*(\#.*)?$/) or
# NEED ANSWER: does Pyrex accept both C and Python types?  if so, update Pyrex regex below to accept ':str' Python types
# NEED ANSWER: does Pyrex accept both C and Python types?  if so, update Pyrex regex below to accept ':str' Python types
# NEED ANSWER: does Pyrex accept both C and Python types?  if so, update Pyrex regex below to accept ':str' Python types
                # Pyrex
                #           $1         $2           $3                                                                                                                                                                                                                                                                                                                  $4            $5    $6
                ($ARG =~ m/^(\s*)def\s+(\w+)\s*\(\s*((?:(?:(?:const\s+)?(?:[\w\.]+\s*(?:\[[\:\d\,\s]+\])?\s+))?[\w\.\*]+(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,\s*)*(?:(?:const\s+)?(?:[\w\.]+\s*(?:\[[\:\d\,\s]+\])?\s+))?[\w\.\*]+(?:\=\s*(?:(?:\'.*\')|(?:\".*\")|(?:\(.*\))|(?:\[.*\])|[\w\.\-\(\)]+))?\s*\,?)?\s*\)\s*(?:->\s*([\w\.]+))?\s*(:)\s*(\#.*)?$/) or
                # Python or Pyrex
                ($ARG =~ m/^(\s*)def\s+(\w+)/)) {
print 'in python_file_to_python_preparsed(), have function, starting header', "\n";
#die 'TMP DEBUG, FUNCTION HEADER';

# NEED UPGRADE: utilize optional trailing comment $6, include in generated Perl source code if present
# NEED UPGRADE: utilize optional trailing comment $6, include in generated Perl source code if present
# NEED UPGRADE: utilize optional trailing comment $6, include in generated Perl source code if present

            chomp $ARG;  # trim trailing newline, if present

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # if multi-line function header, we must receive the function name as part of the first line,
            # in order to pre-parse correctly below
            $python_namespace_name = $2;

            $python_component = 
            {
                component_type => undef,  # set below, either Python::Function or Python::Method or Python::InnerFunction
                decorators => '',  # empty value means no declared decorators; possibly set below
                indentation => $1,  # empty match returns empty string '', not undef
                symbol => $python_namespace_name,  # set now to get non-scoped symbol
                symbol_scoped => undef,  # set below, possibly-scoped symbol
                arguments => '',  # empty value means no declared arguments; possibly set below
                return_type => '',  # empty value means no declared return type; possibly set below
                python_file_path => $self->{python_file_path},
                python_line_number_begin => $python_line_number,
                python_line_number_end => -1,  # negative value means we are currently inside multi-line component
                python_line_number_end_header => -1,  # negative value means we are currently inside multi-line header; possibly set below
                python_source_code => $ARG,  # only function header, remaining source code will be nested in python_preparsed below
                python_preparsed => [],  # nested pre-parsed data structures of all source code inside this function
                python_preparsed_decorators => [],  # nested pre-parsed data structures of all decorators above this function
                perl_source_code => undef  # functions are not translated during pre-parse phase
            };

            # if all function header sub-components have been received, then accept them all;
            # consider final colon ':' captured in $5 to be the ending character of the function header
            if (defined $5) {
print 'in python_file_to_python_preparsed(), have function, ending header', "\n";
                if (defined $3) { $python_component->{arguments} = $3; }
                if (defined $4) { $python_component->{return_type} = $4; }

                # set header ending line number, indicating this is not a multi-line function header
                $python_component->{python_line_number_end_header} = $python_line_number;
            }
            else {
print 'in python_file_to_python_preparsed(), have function, no closing colon found, NOT ending header', "\n";
            }
#die 'TMP DEBUG, PARSE FUNCTION HEADER';

            # look-back to capture function decorators (@abstractmethod, @staticmethod, etc) on previous lines
            while ((scalar @{$python_preparsed_target}) > 0) {
print 'in python_file_to_python_preparsed(), have function, top of look-back loop', "\n";
                # pop blank / whitespace / comment lines onto temporary stack,
                # to either be captured along with decorators or put back if no decorator encountered
                if ($python_preparsed_target->[-1]->isa('Python::Blank') or
                    $python_preparsed_target->[-1]->isa('Python::Whitespace') or
                    $python_preparsed_target->[-1]->isa('Python::Comment')) {
print 'in python_file_to_python_preparsed(), have function, in look-back loop, moving blank / whitespace / comment line to temporary stack', "\n";

                    # utilize as-yet-unused function body python_preparsed as temporary stack
                    unshift @{$python_component->{python_preparsed}}, (pop @{$python_preparsed_target});
                    next;
                }

                # capture function decorators
                # @FOO
                # @FOO.BAR(scope="function")
                if ($python_preparsed_target->[-1]->isa('Python::Unknown') and 
                   ($python_preparsed_target->[-1]->{python_source_code} =~ m/^\s*@.+$/)) {
print 'in python_file_to_python_preparsed(), have function, in look-back loop, capturing decorator \'', $python_preparsed_target->[-1]->{python_source_code}, '\' by deleting sleep_seconds & sleep_retry_multiplier & retries_max object properties & re-blessing from Unknown to FunctionDecorator', "\n";

                    # NEED REMOVE HIGH-MAGIC: how can we re-bless from Unknown with sleep_seconds etc properties to FunctionDecorator w/out it?
                    # NEED REMOVE HIGH-MAGIC: how can we re-bless from Unknown with sleep_seconds etc properties to FunctionDecorator w/out it?
                    # NEED REMOVE HIGH-MAGIC: how can we re-bless from Unknown with sleep_seconds etc properties to FunctionDecorator w/out it?
                    # re-bless from Unknown to FunctionDecorator
                    delete $python_preparsed_target->[-1]->{sleep_seconds};  # HIGH-MAGIC: remove object property
                    delete $python_preparsed_target->[-1]->{sleep_retry_multiplier};  # HIGH-MAGIC
                    delete $python_preparsed_target->[-1]->{retries_max};  # HIGH-MAGIC
                    $python_preparsed_target->[-1] = Python::FunctionDecorator->new($python_preparsed_target->[-1]);  # HIGH-MAGIC: re-bless
                    $python_preparsed_target->[-1]->{component_type} = 'Python::FunctionDecorator';  # LOW-MAGIC: just a string

                    # save decorator source code separately from function header source code,
                    # to allow for proper output code generation,
                    # where the function header source code and the function decorators source code 
                    # must be generator separately for correctness
                    $python_component->{decorators} = 
                        $python_preparsed_target->[-1]->{python_source_code} . "\n" . $python_component->{decorators};
                    chomp $python_component->{decorators};

                    # update starting line of function header to be where first function decorator appears
                    $python_component->{python_line_number_begin} = $python_preparsed_target->[-1]->{python_line_number_begin};

                    # move contents of temporary stack into preparsed decorators
                    unshift @{$python_component->{python_preparsed_decorators}}, @{$python_component->{python_preparsed}};
                    $python_component->{python_preparsed} = [];  # empty temporary stack
    
                    # move formerly-Unknown component into preparsed decorators
                    unshift @{$python_component->{python_preparsed_decorators}}, (pop @{$python_preparsed_target});

                    next;
                }

print 'in python_file_to_python_preparsed(), have function, in look-back loop, leaving loop', "\n";
                last;
            }

            # if not blank / whitespace / comment line or function decorator line,
            # then stop here and restore stack if needed
            if ((scalar @{$python_component->{python_preparsed}}) > 0) {
print 'in python_file_to_python_preparsed(), have function, after look-back loop, restoring stack', "\n";
                push @{$python_preparsed_target}, @{$python_component->{python_preparsed}};
                $python_component->{python_preparsed} = [];
            }

            # determine if function is a normal function, a method, or an inner function
            if ((scalar @{$python_namespaces}) > 0) {
                # prepend all encompassing namespaces to function name, to create scoped function name;
                # immediately enclosing component already has scoped name, no need to loop through entire namespace stack
                $python_namespace_name = $python_namespaces->[-1]->{symbol_scoped} . '.' . $python_namespace_name;
                $python_component->{symbol_scoped} = $python_namespace_name;

                if ($python_namespaces->[-1]->isa('Python::Function')) {
                    # a function defined (nested) inside another function is an inner function
                    $python_component->{component_type} = 'Python::InnerFunction';
                    push @{$python_preparsed_target}, Python::InnerFunction->new($python_component);

print 'in python_file_to_python_preparsed(), Python inner function named \'', $python_namespace_name, '\' defined inside outer function named \'', $python_namespaces->[-1]->{symbol_scoped}, '\'', "\n";
                }
                elsif ($python_namespaces->[-1]->isa('Python::Class')) {
                    # a function defined inside a class is a method
                    $python_component->{component_type} = 'Python::Method';

                    # save scope for use when declaring data type (class name) of $self argument
                    $python_component->{scope} = $python_namespaces->[-1]->{symbol_scoped};

                    push @{$python_preparsed_target}, Python::Method->new($python_component);

print 'in python_file_to_python_preparsed(), Python method named \'', $python_namespace_name, '\' defined inside class named \'', $python_namespaces->[-1]->{symbol_scoped}, '\'', "\n";
print 'in python_file_to_python_preparsed(), Python method named \'', $python_namespace_name, '\', set $python_component->{scope} = \'', $python_component->{scope}, '\'', "\n";
                }
                else {
print 'in python_file_to_python_preparsed(), have enclosing namespace ', Dumper($python_namespaces->[1]), "\n";
                    croak 'ERROR EPYFI004a: Unrecognized enclosing namespace, only Functions & Classes accepted; ', Dumper($python_namespaces->[1]), ', croaking';
                }
            }
            else {
                # a function defined outside all namespaces (classes or functions) is just a normal function
                $python_component->{symbol_scoped} = $python_namespace_name;  # scoped symbol is same as non-scoped for normal functions
                $python_component->{component_type} = 'Python::Function';
                push @{$python_preparsed_target}, Python::Function->new($python_component);
print 'in python_file_to_python_preparsed(), Python normal function named \'', $python_namespace_name, '\' defined outside all namespaces', "\n";
            }

            # can't have the same function declared twice
            if (exists $python_functions->{$python_namespace_name}) {
                if (ref($python_functions->{$python_namespace_name}) eq 'ARRAY') {
                    push @{$python_functions->{$python_namespace_name}}, $python_preparsed_target->[-1];
                    carp 'WARNING WPYFI004b: Python function named \'', $python_namespace_name, '\' already pre-parsed, pushing onto already-created function array, carping';
                }
                elsif ($python_functions->{$python_namespace_name}->isa('Python::Function')) {
                    $python_functions->{$python_namespace_name} = [$python_functions->{$python_namespace_name}, $python_preparsed_target->[-1]];
                    carp 'WARNING WPYFI004c: Python function named \'', $python_namespace_name, '\' already pre-parsed, creating function array, carping';
                }
                else {
                    croak 'ERROR EPYFI004d: Python function named \'', $python_namespace_name, '\' already pre-parsed, did not find either function or function array, croaking';
                }
            }
            else {
                # save reference to current function along with all other functions, for easy name-based access
                $python_functions->{$python_namespace_name} = $python_preparsed_target->[-1];
            }

            # being inside this new function increases the namespace stack (deepens the current scope)
            push @{$python_namespaces}, $python_preparsed_target->[-1];
            next;
        }

        # start class definitions
        # NEED ANSWER: are all Python classes multi-line?
        # DEV NOTE: can have whitespace around commas
        # DEV NOTE: can have whitespace but NOT newline in between class name and open parentheses
        # DEV NOTE: can have whitespace but NOT newline in between close parentheses and colon
        # DEV NOTE: can have trailing comma at the end of parent class list

        # Python class header examples
        # class FOO:
        # class FOO(BAR):
        # class FOO ( B.AR ) :
        # class FOO (
        #
        # ) :
        # class FOO(BAR, BAT, BAX):
        # class FOO(B.AR, BA.T, BAX):
        # class _FOO (BAR, BAT, BAX=BAY) :
        # class FOO ( BAR,
        #     BAT, BAX,
        # ) :

        # Pyrex class header examples
        # cdef class FOO:
        # cdef class FOO(BAR):

        # DEV NOTE: either match the entire regex for single-line class header,
        # or match only the start of the class header 'class FOO(' and 
        # start multi-line component to accumulate source code lines until entire regex can be matched
        # DEV NOTE, CORRELATION PYFI101: all regex changes must be reflected in both locations,
        # the only difference should be the optional trailing comment pattern \s*(?:\#.*\n)?\s*
        # which is not in the header-opening regex and is used twice in the header-closing regex;
        #                   $1           $2              $3                                              $4    $5
        elsif ( # Python
                ($ARG =~ m/^(\s*)class\s+(\w+)\s*(?:\(\s*((?:[\w\.=]+\s*\,\s*)*[\w\.=]+\s*\,?)?\s*\)\s*)?(:)\s*(\#.*)?$/) or
                ($ARG =~ m/^(\s*)class\s+(\w+)\s*\(/) or
                # Pyrex
                ($ARG =~ m/^(\s*)cdef\s+class\s+(\w+)\s*(?:\(\s*((?:[\w\.=]+(?:\{\{\w+\}\})?[\w\.=]*\s*\,\s*)*[\w\.=]+(?:\{\{\w+\}\})?[\w\.=]*\s*\,?)?\s*\)\s*)?(:)\s*(\#.*)?$/) or
                ($ARG =~ m/^(\s*)cdef\s+class\s+(\w+)\s*\(/)) {

# NEED UPGRADE: utilize optional trailing comment $5, include in generated Perl source code if present
# NEED UPGRADE: utilize optional trailing comment $5, include in generated Perl source code if present
# NEED UPGRADE: utilize optional trailing comment $5, include in generated Perl source code if present

print 'in python_file_to_python_preparsed(), have class, starting header', "\n";

            chomp $ARG;  # trim trailing newline, if present

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # if multi-line class header, we must receive the class name as part of the first line,
            # in order to pre-parse correctly below
            $python_namespace_name = $2;

            $python_component = 
            {
                component_type => undef,  # set below, either Python::Class or Python::LocalClass or Python::InnerClass
                indentation => $1,  # empty match returns empty string '', not undef
                symbol => $python_namespace_name,
                parents => '',  # empty value means no declared parent classes; possibly set below
                python_file_path => $self->{python_file_path},
                python_line_number_begin => $python_line_number,
                python_line_number_end => -1,  # negative value means we are currently inside multi-line component
                python_line_number_end_header => -1,  # negative value means we are currently inside multi-line header; possibly set below
                python_source_code => $ARG,  # only class header, remaining source code will be nested in python_preparsed below
                python_preparsed => [],  # nested pre-parsed data structures of all source code inside this class
                perl_source_code => undef  # classes are not translated during pre-parse phase
            };

            # if all class header sub-components have been received, then accept them all;
            # consider final colon ':' captured in $4 to be the ending character of the class header
            if (defined $4) {
print 'in python_file_to_python_preparsed(), have class, ending header', "\n";
                if (defined $3) { $python_component->{parents} = $3; }

                # set header ending line number, indicating this is not a multi-line class header
                $python_component->{python_line_number_end_header} = $python_line_number;
            }
            else {
print 'in python_file_to_python_preparsed(), have class, no closing colon found, NOT ending header', "\n";
            }
#die 'TMP DEBUG, PARSE CLASS HEADER';

            # determine if class is a normal class, a local class, or an inner class
            if ((scalar @{$python_namespaces}) > 0) {
                # prepend all encompassing namespaces to class name, to create scoped class name;
                # immediately enclosing component already has scoped name, no need to loop through entire namespace stack
                $python_namespace_name = $python_namespaces->[-1]->{symbol_scoped} . '.' . $python_namespace_name;
                $python_component->{symbol_scoped} = $python_namespace_name;

                if ($python_namespaces->[-1]->isa('Python::Class')) {
                    # a class defined (nested) inside another class is an inner class
                    $python_component->{component_type} = 'Python::InnerClass';
                    push @{$python_preparsed_target}, Python::InnerClass->new($python_component);

print 'in python_file_to_python_preparsed(), Python inner class named \'', $python_namespace_name, '\' defined inside outer class named \'', $python_namespaces->[-1]->{symbol_scoped}, '\'', "\n";
                }
                elsif ($python_namespaces->[-1]->isa('Python::Function')) {
                    # a class defined inside a function is a local class
                    $python_component->{component_type} = 'Python::LocalClass';
                    push @{$python_preparsed_target}, Python::LocalClass->new($python_component);

print 'in python_file_to_python_preparsed(), Python local class named \'', $python_namespace_name, '\' defined inside function named \'', $python_namespaces->[-1]->{symbol_scoped}, '\'', "\n";
                }
                else {
print 'in python_file_to_python_preparsed(), have enclosing namespace ', Dumper($python_namespaces->[1]), "\n";
                    croak 'ERROR EPYFI005a: Unrecognized enclosing namespace, only Functions & Classes accepted; ', Dumper($python_namespaces->[1]), ', croaking';
                }
            }
            else {
                # a class defined outside all namespaces (classes or functions) is just a normal class
                $python_component->{symbol_scoped} = $python_namespace_name;  # scoped symbol is same as non-scoped for normal classes
                $python_component->{component_type} = 'Python::Class';
                push @{$python_preparsed_target}, Python::Class->new($python_component);
            }

            # can't have the same class declared twice
            if (exists $python_classes->{$python_namespace_name}) {
                croak 'ERROR EPYFI005b: Python class named \'', $python_namespace_name, '\' already pre-parsed, croaking';
            }

            # save reference to current class along with all other classes, for easy name-based access
            $python_classes->{$python_namespace_name} = $python_preparsed_target->[-1];

            # being inside this new class increases the namespace stack (deepens the current scope)
            push @{$python_namespaces}, $python_preparsed_target->[-1];
            next;
        }
        else {
print 'in python_file_to_python_preparsed(), have UNKNOWN line of code', "\n";
            chomp $ARG;  # trim trailing newline, if present

            # update last active character
            $python_last_active_character = $self->python_last_active_character_find($python_last_active_character, $ARG);
print 'in python_file_to_python_preparsed(), possibly updated last active character to \'', $python_last_active_character, '\'', "\n";

            # ensure we correctly parse all namespaces (functions & classes)
            if ($ARG =~ m/^(\s*)def\s+/) {
                croak 'ERROR EPYFI006a: Python function with UNKNOWN format, croaking';
            }
            elsif ($ARG =~ m/^(\s*)class\s+/) {
                croak 'ERROR EPYFI006b: Python class with UNKNOWN format, croaking';
            }

            # DEV NOTE, CORRELATION PYFI102: all Unknown logic in this if-elsif-else block must be copied
            # check if previous component was same type
            if (((scalar @{$python_preparsed_target}) > 0) and
                $python_preparsed_target->[-1]->isa('Python::Unknown')) {
print 'in python_file_to_python_preparsed(), have UNKNOWN line, accumulating', "\n";
                # accumulate multiple single-line components into a multi-line component
                $python_preparsed_target->[-1]->{python_source_code} .= "\n" . $ARG;
                # update ending line number
                $python_preparsed_target->[-1]->{python_line_number_end} = $python_line_number;
            }
            # merge Unknown components when separated by only Blank components
            elsif (((scalar @{$python_preparsed_target}) > 1) and
                $python_preparsed_target->[-1]->isa('Python::Blank') and
                $python_preparsed_target->[-2]->isa('Python::Unknown')) {
print 'in python_file_to_python_preparsed(), have UNKNOWN line preceded by blank line(s) and other UNKNOWN line(s), merging components', "\n";

                # merge 3 components into a single component;
                # Unknown + Blank + Unknown = Unknown
                $python_preparsed_target->[-2]->{python_source_code} .= 
                    "\n" . $python_preparsed_target->[-1]->{python_source_code} . "\n" . $ARG;
                # update ending line number
                $python_preparsed_target->[-2]->{python_line_number_end} = $python_line_number;
                # discard now-redundant Blank component
                pop @{$python_preparsed_target};
            }
            else {
print 'in python_file_to_python_preparsed(), have UNKNOWN line, creating', "\n";
                # create new component
                push @{$python_preparsed_target},
                Python::Unknown->new(
                {   
                    component_type => 'Python::Unknown',
                    python_line_number_begin => $python_line_number,
                    python_line_number_end => $python_line_number,
                    python_source_code => $ARG,
                    perl_source_code => undef  # unknown code is not translated during pre-parse phase
                });
            }

            next;
        }
    }

print 'in python_file_to_python_preparsed(), EOF end of file \'', $self->{python_file_path}, '\'', "\n";

    # close file after reading
    close($PYTHON_FILE)
        or croak 'ERROR EPYFI000b: failed to close Python source code file \'', $self->{python_file_path}, 
            '\' after reading, received OS error message \'', $OS_ERROR, '\', croaking';

    # ensure we finish parsing all multi-line function headers
    if (((scalar @{$python_preparsed_target}) > 0) and
        $python_preparsed_target->[-1]->isa('Python::Function') and 
       ($python_preparsed_target->[-1]->{python_line_number_end_header} < 0)) {
        croak 'ERROR EPYFI007: failed to end header for Python function \'', 
            $python_preparsed_target->[-1]->{symbol_scoped}, '\', croaking';
    }

    # Python source code file is ended; remove all remaining namespaces from stack
    while ((scalar @{$python_namespaces}) > 0) {
print 'in python_file_to_python_preparsed(), ending multi-line namespace \'', $python_namespaces->[-1]->{symbol_scoped}, '\'', "\n";
        # set ending line number, indicating we are no longer inside this multi-line component;
        # the multi-line component actually ended on the last line number
        $python_namespaces->[-1]->{python_line_number_end} = $python_line_number;

        pop @{$python_namespaces};
    }

    # remove extra trailing newline, to match original input source code
    # DEV NOTE: while loop causes extraneous newline to be added at end of last line!
    chomp $self->{python_source_code};

print 'in python_file_to_python_preparsed(), after reading & closing input file, about to return $self->{python_preparsed} = ', Dumper($self->{python_preparsed}), "\n";

    return $self->{python_preparsed};
}

1;

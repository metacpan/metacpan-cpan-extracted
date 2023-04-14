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
# ABSTRACT: an include statement
#use RPerl;
package Python::Include;
use strict;
use warnings;
our $VERSION = 0.008_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Python::Component);
use Python::Component;

# [[[ DATA TYPES ]]]
package Python::Include::hashref::hashref; 1;
package Python::Include;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print op
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ INCLUDES ]]]
use Perl::Types;
#use re 'debugcolor';  # output regex debugging info
use Champ;

# DEV NOTE: not actually used in this class, but needed so python_preparsed_to_perl_source() 
# can accept the same args as all Python::Component classes
use OpenAI::API;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    component_type => my string $TYPED_component_type = 'Python::Function',
    python_file_path => my string $TYPED_python_file_path = undef,
    python_line_number_begin => my integer $TYPED_python_line_number_begin = undef,
    python_line_number_end => my integer $TYPED_python_line_number_end = undef,
    python_source_code => my string $TYPED_python_source_code = undef,
    python_modules => my string::arrayref $TYPED_python_modules = undef,
    python_subcomponents => my string::arrayref $TYPED_python_subcomponents = undef,
    python_alias => my string $TYPED_python_alias = undef,
    python_has_parentheses => my boolean $TYPED_python_has_parentheses = undef,
    perl_source_code => my string $TYPED_perl_source_code = undef,
};

# [[[ SUBROUTINES ]]]

# PYIN01x
sub python_preparsed_to_perl_source {
# translate a chunk of Python source code into Perl source code
    { my string $RETURN_TYPE };
    ( my Python::Include $self, my OpenAI::API $openai ) = @ARG;

    # DEV NOTE: this subroutine should handle most of the common types of includes in Python, as described in unofficial Python websites
    # https://note.nkmk.me/en/python-import-usage
    # https://realpython.com/python-import/

    # NEED UPGRADE: correctly handle all advanced functionality and edge cases, as specified in the official Python documentation
    # https://docs.python.org/3/reference/import.html

    # error if no OpenAI API
    if (not defined $openai) {
        croak 'ERROR EPYIN010: undefined OpenAI API, croaking';
    }

    # error or warning if no Python source code
    if ((not exists  $self->{python_source_code}) or
        (not defined $self->{python_source_code}) or
        ($self->{python_source_code} eq q{})) {
        croak 'ERROR EPYIN011: non-existent or undefined or empty Python source code, croaking';
    }

    # DEV NOTE, PYIN012: $self->{python_preparsed} not used in this class, no need to error check

    # initialize object properties
    $self->{python_modules} = [undef];
    $self->{python_subcomponents} = [undef];
    $self->{python_alias} = undef;

print 'in Python::Include::python_preparsed_to_perl_source(), have champ($self->{python_source_code}) = \'', champ($self->{python_source_code}), '\'', "\n";

    # remove all backslashes, which can only appear at the end of a line and which only signify line continuation;
    # since \s matches \n, removal of backslashes allows all the following regexes to automatically work for multi-line includes
    my string $python_source_code_clean = $self->{python_source_code};
    $python_source_code_clean =~ s/\\//gxms;

    # also remove all trailing comments, because only comments on the last line are correctly matched by the regexes below
    $python_source_code_clean =~ s/\#[^\n]*\n/\n/gxms;

print 'in Python::Include::python_preparsed_to_perl_source(), have champ($python_source_code_clean) = \'', champ($python_source_code_clean), '\'', "\n";

    # DEV NOTE, CORRELATION PYIN000: any changes to test includes below must also be made in t/00_includes.py
    # DEV NOTE: comments do not need to be preceded by whitespace
    # import FOO
    # import F.OO
    # import F.OO# test comment
    # import F.OO  # test comment
    # import \
    #     FOO
    if ($python_source_code_clean =~ m/^\s*import\s+([\w\.]+)\s*(\#.*)?$/) {
print 'in Python::Include::python_preparsed_to_perl_source(), matched regex #0, have $1 = \'', $1, '\'', "\n";
        $self->{python_modules} = [$1];
        $self->{perl_source_code} = 'use ' . $1 . ';';
    }
    # DEV NOTE: commas may be either preceded or followed by optional whitespace
    # import FOO, BAR, BAT, BAX
    # import F.OO , B.AR, BA.T, B.A.X
    # import F.OO,B.AR,BA.T,B.A.X# test comment
    # import F.OO, B.AR, BA.T, B.A.X  # test comment
    # import \
    #     FOO, B.AR, \
    #     BA.T, B.A.X  # test comment
    elsif ($python_source_code_clean =~ m/^\s*import\s+((?:[\w\.]+\s*\,\s*)+[\w\.]+)\s*(\#.*)?$/) {
print 'in Python::Include::python_preparsed_to_perl_source(), matched regex #1, have $1 = \'', $1, '\'', "\n";
        $self->{python_modules} = [split /\,\s+/, $1];
        foreach my string $python_module (@{$self->{python_modules}}) {
            $self->{perl_source_code} .= 'use ' . $python_module . ';  ';
        }
        substr $self->{perl_source_code}, -2, 2, '';  # strip trailing '  ' created by for() loop above
    }
    # from FOO import BAR
    # from F.OO import B.AR
    # from F.OO import B.AR# test comment
    # from F.OO import B.AR  # test comment
    # from \
    #     F.OO \
    #     import \
    #     B.AR  # test comment
    # from . import BAR
    # from . import B.AR
    # from . import B.AR# test comment
    # from . import B.AR  # test comment
    # from \
    #     . \
    #     import \
    #     B.AR  # test comment
    elsif ($python_source_code_clean =~ m/^\s*from\s+([\w\.]+)\s+import\s+([\w\.]+)\s*(\#.*)?$/) {
print 'in Python::Include::python_preparsed_to_perl_source(), matched regex #2, have $1 = \'', $1, '\', $2 = \'', $2, '\'', "\n";
        $self->{python_modules} = [$1];
        $self->{python_subcomponents} = [$2];
        $self->{perl_source_code} = 'use ' . $1 . ' qw(' . $2 . ');';
    }
    # DEV NOTE: commas may be either preceded or followed by optional whitespace
    # from FOO import BAR, BAT, BAX
    # from F.OO import B.AR , BA.T, B.A.X
    # from F.OO import B.AR,BA.T,B.A.X# test comment
    # from F.OO import B.AR, BA.T, B.A.X  # test comment
    # from \
    #     F.OO \
    #     import B.AR, \
    #     BA.T, B.A.X  # test comment
    # from FOO import \
    #     BAR, \
    #     BAT, \
    #     BAX
    # from FOO import FU, FEW, \
    #     BAR, BHAR \
    #     ,BAT, \
    #     BAX, BHAX
    # from F.OO import F.U, F.E.W, \
    #     B.AR, BH.AR, \
    #     BA.T, \
    #     B.A.X, B.H.A.X  # test comment
    elsif ($python_source_code_clean =~ m/^\s*from\s+([\w\.]+)\s+import\s+((?:[\w\.]+\s*\,\s*)+[\w\.]+)\s*(\#.*)?$/) {
print 'in Python::Include::python_preparsed_to_perl_source(), matched regex #3, have $1 = \'', $1, '\', $2 = \'', $2, '\'', "\n";
        $self->{python_modules} = [$1];
        $self->{python_subcomponents} = [split /\,\s+/, $2];
        $self->{perl_source_code} = 'use ' . $1 . ' qw(' . join(' ', @{$self->{python_subcomponents}}) . ');';
    }
    # DEV NOTE: parentheses do not need to be surrounded by whitespace
    # DEV NOTE: commas may be either preceded or followed by optional whitespace
    # DEV NOTE: extra commas are allowed at the end of parentheses-enclosed lists
    # from FOO import ( BAR, BAT, BAX )
    # from FOO import ( B.AR , BA.T, B.A.X, )
    # from FOO import(B.AR,BA.T,B.A.X)#test comment
    # from FOO import ( B.AR, BA.T, B.A.X )  # test comment
    # NEED ANSWER: how to handle comments in multi-line includes?
    # from FOO import (
    #     BAR,
    #     BAT,
    #     BAX
    # )
    # from FOO import ( FU, FEW,
    #     BAR, BHAR,
    #     BAT,
    #     BAX, BHAX,
    # )
    # from F.OO import ( F.U, F.E.W,
    #     B.AR, BH.AR,
    #     BA.T,
    #     B.A.X, B.H.A.X
    # )
    # from FOO import ( \
    #     BAR, \
    #     BAT,# test comment
    #     BAX \
    # )# test comment
    # from FOO import ( FU, FEW, \
    #     BAR, BHAR, \
    #     BAT,
    #     BAX, BHAX \
    # )
    # from \
    #     F.OO \
    #     import \
    #     ( \
    #     F.U, F.E.W, \
    #     B.AR, BH.AR, \
    #     BA.T, \
    #     B.A.X, B.H.A.X \
    # )
    elsif ($python_source_code_clean =~ m/^\s*from\s+([\w\.]+)\s+import\s*\(\s*((?:[\w\.]+\s*\,\s*)+[\w\.]+\s*\,?)\s*\)\s*(\#.*)?$/) {
print 'in Python::Include::python_preparsed_to_perl_source(), matched regex #4, have $1 = \'', $1, '\', $2 = \'', $2, '\'', "\n";
        $self->{python_modules} = [$1];
        $self->{python_subcomponents} = [split /\,\s+/, $2];
        $self->{perl_source_code} = 'use ' . $1 . ' qw(' . join(' ', @{$self->{python_subcomponents}}) . ');';
    }
    # import FOO as F
    # import F.OO as F
    # import F.OO as F# test comment
    # import F.OO as F  # test comment
    # import \
    #     F.OO \
    #     as \
    #     F  # test comment
    elsif ($python_source_code_clean =~ m/^\s*import\s+([\w\.]+)\s+as\s+([\w\.]+)\s*(\#.*)?$/) {
print 'in Python::Include::python_preparsed_to_perl_source(), matched regex #5, have $1 = \'', $1, '\', $2 = \'', $2, '\'', "\n";
        $self->{python_modules} = [$1];
        $self->{python_alias} = $2;
        # NEED ANSWER: does this work???
        # NEED ANSWER: do we need the 'use FOO qw(:ALL);' below?
        # NEED ANSWER: do we need to use Exporter below???
        # alias a Perl package/class as another pre-existing package/class
        # by creating a new empty package that just inherits from the other one
        # eval(q{package F; use parent qw(FOO); use FOO qw(:ALL); 1;});  use F;
        $self->{perl_source_code} = 'eval(q{package ' . $2 . '; use parent qw(' . $1 . '); use ' . $1 . ' qw(:ALL); 1;});  use ' . $2 . ';';
    }
    # from FOO import BAR as B
    # from F.OO import B.AR as B
    # from F.OO import B.AR as B# test comment
    # from F.OO import B.AR as B  # test comment
    # from \
    #     F.OO \
    #     import \
    #     B.AR \
    #     as \
    #     B  # test comment
    elsif ($python_source_code_clean =~ m/^\s*from\s+([\w\.]+)\s+import\s+([\w\.]+)\s+as\s+([\w\.]+)\s*(\#.*)?$/) {
print 'in Python::Include::python_preparsed_to_perl_source(), matched regex #6, have $1 = \'', $1, '\', $2 = \'', $2, '\', $3 = \'', $3, '\'', "\n";
        $self->{python_modules} = [$1];
        $self->{python_subcomponents} = [$2];
        $self->{python_alias} = $3;
        # NEED ANSWER: does this work???
        # alias a Perl function/variable/etc as another pre-existing function/variable/etc
        # by creating a new typeglob and setting it to the other one
        # use FOO;  *B = *FOO::BAR;
        $self->{perl_source_code} = 'use ' . $1 . ';  *' . $3 . ' = *' . $1 . '::' . $2 . ';';
    }
    else {
        croak 'ERROR EPYIN013: cannot parse unrecognized include line \'', $self->{python_source_code}, '\', croaking';
    }

    # NEED ANSWER: is the following statement correct?
    # Python syntax does not allow an import statement with both multiple modules and multiple subcomponents simultaneously
    if (((scalar @{$self->{python_modules}}) > 1) and 
        ((scalar @{$self->{python_subcomponents}}) > 1)) {
        croak 'ERROR EPYIN014: multiple modules and multiple subcomponents should never be parsed in a single include statement, croaking';
    }

    # for multi-line includes, append newline character(s) to generated Perl source code,
    # in order to match original Python line spacing
    my string::arrayref $perl_source_code_lines = [split(/\n/, $self->{perl_source_code})];
    my integer $line_count_perl   = scalar @{$perl_source_code_lines};
    # add 1 because beginning & ending on the same line counts as 1 line
    my integer $line_count_python = ($self->{python_line_number_end} - $self->{python_line_number_begin}) + 1;
    my integer $line_count_difference = $line_count_python - $line_count_perl;
print 'in Python::Include::python_preparsed_to_perl_source(), have newline-appended $line_count_difference = ', $line_count_difference, "\n";
    if ($line_count_difference > 0) {
        for (my integer $i = 0; $i < $line_count_difference; $i++) {
            push @{$perl_source_code_lines}, '';
print 'in Python::Include::python_preparsed_to_perl_source(), appending newline to match Python multi-line include', "\n";
        }
        $self->{perl_source_code} = join "\n", @{$perl_source_code_lines};
print 'in Python::Include::python_preparsed_to_perl_source(), have newline-appended $self->{perl_source_code} = \'', $self->{perl_source_code}, '\'', "\n";
#die 'TMP DEBUG, MULTI-LINE INCLUDES';
    }

print 'in Python::Include::python_preparsed_to_perl_source(), end of subroutine, about to return $self->{perl_source_code} = \'', $self->{perl_source_code}, '\'', "\n";
#die 'TMP DEBUG, INCLUDES';

    return $self->{perl_source_code};
}

1;

#
# This file is part of App-PythonToPerl
#
# This software is Copyright (c) 2023 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use Test2::V0;
use Perl::Types;
use Python::File;
use Python::Include;
use Python::Function;
use Python::Class;
use App::PythonToPerl;

our $VERSION = 0.005_000;

plan tests => 5;

#diag '<<< DEBUG >>> have $foo = ', $foo, "\n";  # output meant to be remain enabled, prints to STDERR & turns every line into a comment
#print '<<< DEV >>> have $foo = ', $foo, "\n";   # output meant to be disabled except during development

# NEED UPGRADE: accept multiple file and/or directory names as input, not just includes file(s); rename to t/00_roundtrip.t
# NEED UPGRADE: accept multiple file and/or directory names as input, not just includes file(s); rename to t/00_roundtrip.t
# NEED UPGRADE: accept multiple file and/or directory names as input, not just includes file(s); rename to t/00_roundtrip.t

# path to Python input file
my string $python_file_path = 't/00_includes.py';
print '<<< DEV >>> have $python_file_path = \'', $python_file_path, '\'', "\n";

# file containing correct pre-parsed Python, in Data::Dumper format
my string $python_file_path_correct = $python_file_path . '.preparsed';
print '<<< DEV >>> have $python_file_path_correct = \'', $python_file_path_correct, '\'', "\n";


# [ GENERATE PRE-PARSED DATA STRUCTURES ]

# create object to handle Python input file
my Python::File $python_file = Python::File->new({python_file_path => $python_file_path});

# create and initialize pre-parsed Python data structures,
# outer hashes are keyed on file paths, then inner structures are Python::File objects or hashes keyed on fully-scoped symbol names
my Python::File::hashref                $python_files     = { $python_file_path => $python_file };
my Python::Include::hashref::hashref    $python_includes_all  = { $python_file_path => {}, index_max => -1 };
my Python::Function::hashref::hashref   $python_functions_all = { $python_file_path => {} };
my Python::Class::hashref::hashref      $python_classes_all   = { $python_file_path => {} };

# PRE-PARSE PYTHON FILE
#print 'about to call python_file_to_python_preparsed()...', "\n";
# DEV NOTE: capturing the return value of python_file_to_python_preparsed() is purely optional,
# the pre-parsed output will also be stored in the Python::File object's python_preparsed property 
ok(
    my Python::Component::arrayref $python_preparsed =
        $python_file->python_file_to_python_preparsed(
            $python_includes_all->{$python_file_path},
            $python_functions_all->{$python_file_path},
            $python_classes_all->{$python_file_path}
        ),
    'Generate pre-parsed Python via python_file_to_python_preparsed()'
);
#print 'ret from call to python_file_to_python_preparsed(), have     $python_file = ', "\n", Dumper($python_file), "\n";
#print 'ret from call to python_file_to_python_preparsed(), have     $python_files = ', Dumper($python_files), "\n";
#print 'ret from call to python_file_to_python_preparsed(), received $python_preparsed = ', Dumper($python_preparsed), "\n";
#print 'ret from call to python_file_to_python_preparsed(), received $python_includes_all = ', Dumper($python_includes_all), "\n";
#print 'ret from call to python_file_to_python_preparsed(), received $python_functions_all = ', Dumper($python_functions_all), "\n";
#print 'ret from call to python_file_to_python_preparsed(), received $python_classes_all = ', Dumper($python_classes_all), "\n";

# DEV NOTE: to re-generate the correct pre-parsed file, die here and copy output of Dumper($python_file) above
#die 'TMP DEBUG, TEST PRE-PARSED';


# [ COMPARE PRE-PARSED PYTHON WITH ORIGINAL PRE-PARSED PYTHON ]

# the correct pre-parsed Python, in Data::Dumper format
my string $python_file_correct_dumper = '';

subtest 'Read file containing correct pre-parsed Python' => sub {

    # open correct pre-parsed file for reading
    open (my filehandleref $PYTHON_FILE_CORRECT, '<', $python_file_path_correct)
        or croak 'ERROR EPYTOPL100: failed to open correct pre-parsed Python file \'', $python_file_path_correct,
            '\' for reading, received OS error message \'', $OS_ERROR, '\', croaking';  # DEV NOTE: $OS_ERROR == $!

    # loop through each line, read all file contents into variable in memory
    while (<$PYTHON_FILE_CORRECT>) {
        $python_file_correct_dumper .= $ARG;  # DEV NOTE: $ARG == $_
    }
#print '<<< DEV >>> after reading file, have $python_file_correct_dumper = ', "\n", $python_file_correct_dumper, "\n";

    # close correct pre-parsed file after reading
    close($PYTHON_FILE_CORRECT)
        or croak 'ERROR EPYTOPL101: failed to close Python pre-parsed file \'', $python_file_path_correct,
            '\' after reading, received OS error message \'', $OS_ERROR, '\', croaking';

    pass();
};

# evaluate Data::Dumper data structure back into memory
my $VAR1;  # must initialize default temporary variable used by Data::Dumper(), or else eval() below will return undef
my Python::File $python_file_correct;
$python_file_correct_dumper = '$python_file_correct = ' . $python_file_correct_dumper;
#print '<<< DEV >>> before eval(), have $python_file_correct_dumper = ', "\n", $python_file_correct_dumper, "\n";
eval $python_file_correct_dumper;
#print '<<< DEV >>> after eval(), have $python_file_correct = ', "\n", Dumper($python_file_correct), "\n";
#print '<<< DEV >>> after eval(), have $VAR1 = ', "\n", Dumper($VAR1), "\n";


# [ COMPARE PRE-PARSED DATA STRUCTURES WITH ORIGINAL PRE-PARSED DATA STRUCTURES ]

# compare pre-generated includes with just-generated includes
is ($python_file_correct, $python_file, 'Pre-parsed Python file matches correct pre-parsed Python file');


# [ GENERATE DE-PARSED PYTHON SOURCE CODE ]

#print '<<< DEV >>> about to call python_preparsed_to_python_source()...', "\n";
# DEV NOTE: capturing the return value of python_preparsed_to_python_source() is purely optional,
# the source code output will also be stored in the Python::File object's python_source_full property 
ok(
    my string $python_source_code = $python_file->python_preparsed_to_python_source(),
    'Generate de-parsed Python source code via python_preparsed_to_python_source()'
);
#print '<<< DEV >>> ret from call to python_preparsed_to_python_source(), received $python_source_code = ', "\n", $python_source_code, "\n";
#print '<<< DEV >>> ret from call to python_preparsed_to_python_source(), received $python_file->{python_source_code_full} = ', "\n", 'BEGIN', $python_file->{python_source_code_full}, 'END', "\n";
#print '<<< DEV >>> ret from call to python_preparsed_to_python_source(), have $python_file->{python_source_code} = ', "\n", 'BEGIN', $python_file->{python_source_code}, 'END', "\n";


# [ COMPARE DE-PARSED PYTHON SOURCE CODE WITH ORIGINAL PYTHON SOURCE CODE ]

is ($python_file->{python_source_code}, $python_file->{python_source_code_full}, 'De-parsed Python source code matches original Python source code');


# [ GENERATE TRANSLATED & DE-PARSED PERL SOURCE CODE ]

# NEED CODE
# NEED CODE
# NEED CODE

done_testing();


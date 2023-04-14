#!/usr/bin/perl
#
# This file is part of App-PythonToPerl
#
# This software is Copyright (c) 2023 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use strict;
use warnings;
our $VERSION = 0.003_000;

use Python::File;

# save STDOUT file handle;
# if 2nd command-line argument is present and true, then disable both STDOUT & STDERR
open my $stdout, '>&STDOUT';
if ((defined $ARGV[1]) and $ARGV[1]) {
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
}

# create new Python file object, from Python file path provided in 1st command-line argument
my $python_file = Python::File->new({python_file_path => $ARGV[0]});

# pre-parse Python file, a good way to quickly test pre-parser w/out translating
#$python_file->python_file_to_python_preparsed({}, {}, {}); 

# generate Perl file path
my $perl_file = $python_file->python_file_path_to_perl_file_path();

# re-enable STDOUT only
open STDOUT,'>&', $stdout; 

# print Perl file path in env var format, to be eval'd from a bash script
print 'PERL_FILE=\'', $perl_file, '\'';

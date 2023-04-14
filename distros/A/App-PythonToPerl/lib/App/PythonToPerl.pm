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
# ABSTRACT: translates Python source code into Perl source code
#use RPerl;
package App::PythonToPerl;
use strict;
use warnings;
our $VERSION = 0.021_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants

# [[[ EXPORTS ]]]
#use RPerl::Exporter qw(import);
use Exporter qw(import);
our @EXPORT    = qw(python_file_to_perl_files__follow_includes python_files_to_perl_files);

# [[[ INCLUDES ]]]
use Perl::Types;
use OpenAI::API;

# [[[ CONSTANTS ]]]
# ...

# [[[ SUBROUTINES ]]]

# APPYPL01x
sub python_files_to_perl_files {
# translate multiple directoreis and files of Python source code into Perl, and save the new Perl files
    { my string::arrayref $RETURN_TYPE };
    (   my OpenAI::API $openai,
        my string::arrayref $python_file_paths,
        # NEED OTHER ARGS?
        # NEED OTHER ARGS?
        # NEED OTHER ARGS?
    ) = @ARG;

    my string::arrayref $perl_file_paths = [];

# NEED CODE
# NEED CODE
# NEED CODE

    return $perl_file_paths;
}


# APPYPL00x
sub python_file_to_perl_files__follow_includes {
# translate a file of Python source code into Perl, and save the new Perl file; follow all includes & recurse
    { my string::arrayref $RETURN_TYPE };
    (   my OpenAI::API $openai,
        my string $python_file_path,
        # NEED OTHER ARGS?
        # NEED OTHER ARGS?
        # NEED OTHER ARGS?
    ) = @ARG;

    my string::arrayref $perl_file_paths = [];

# NEED CODE
# NEED CODE
# NEED CODE

# NEED ENABLE
#    my string::arrayref $python_includes_file_names = [];
#
#    # convert Python include source code to Python file name
#    foreach my string $python_include (@{$python_includes}) {
#        push @{$python_includes_file_names}, python_include_to_file_name($python_include);
#    }
#
#    # for all includes, recursively translate all Python files to Perl
#    my string::arrayref $perl_includes_file_names = [];
#    foreach my string $python_include_file_name (@{$python_includes_file_names}) {
#        push @{$perl_includes_file_names}, python_file_to_perl_file($openai, $python_include_file_name);
#    }


    return $perl_file_paths;
}

1;  # end of package

#!/usr/bin/perl
#
# Build script for the AFS::PAG distribution.
#
# Written by Russ Allbery <rra@cpan.org>
# Copyright 2013, 2014
#     The Board of Trustees of the Leland Stanford Junior University
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

use 5.010;
use autodie;
use strict;
use warnings;

use Config::AutoConf;
use File::Basename qw(basename);
use File::Path qw(remove_tree);
use File::Spec;
use Module::Build;

# Check whether it's possible to link a program that uses a particular
# function.  This is written like a Config::AutoConf method and should ideally
# be incorporated into that module.  This macro caches its result in the
# ac_cv_func_FUNCTION variable.
#
# $self         - The Config::AutoConf state object
# $function     - The function to check for
# $found_ref    - Code reference to call if the function was found
# $notfound_ref - Code reference to call if the function wasn't found
#
# Returns: True if the function was found, false otherwise
sub check_func {
    my ($self, $function, $found_ref, $notfound_ref) = @_;
    $self = $self->_get_instance();

    # Build the name of the cache variable.
    my $cache_name = $self->_cache_name('func', $function);

    # Wrap the actual check in a closure so that we can use check_cached.
    my $check_sub = sub {
        my $have_func = $self->link_if_else($self->lang_call(q{}, $function));
        if ($have_func) {
            if (defined($found_ref) && ref($found_ref) eq 'CODE') {
                $found_ref->();
            }
        } else {
            if (defined($notfound_ref) && ref($notfound_ref) eq 'CODE') {
                $notfound_ref->();
            }
        }
        return $have_func;
    };

    # Run the check and cache the results.
    return $self->check_cached($cache_name, "for $function", $check_sub);
}

# The same as check_func, but takes a list of functions to look for and checks
# for each in turn.  Define HAVE_FUNCTION for each function that was found,
# and also run the $found_ref code each time a function was found.  Run the
# $notfound_ref code each time a function wasn't found.  Both code references
# are passed the name of the function that was found.
#
# $self          - The Config::AutoConf state object
# $functions_ref - Reference to an array of functions to check for
# $found_ref     - Code reference to call if a function was found
# $notfound_ref  - Code reference to call if a function wasn't found
#
# Returns: True if all functions were found, false otherwise.
sub check_funcs {
    my ($self, $functions_ref, $user_found_ref, $user_notfound_ref) = @_;
    $self = $self->_get_instance();

    # Build the code reference to run when a function was found.  This defines
    # a HAVE_FUNCTION symbol, plus runs the current $found_ref if there is
    # one.
    my $func_found_ref = sub {
        my ($function) = @_;

        # Generate the name of the symbol we'll define.
        my $have_func_name = 'HAVE_' . uc($function);
        $have_func_name =~ tr/_A-Za-z0-9/_/c;

        # Define the symbol.
        $self->define_var($have_func_name, 1,
            "Defined when $function is available");

        # Run the user-provided hook, if there is one.
        if (defined($user_found_ref) && ref($user_found_ref) eq 'CODE') {
            $user_found_ref->($function);
        }
    };

    # Go through the list of functions and call check_func for each one.  We
    # generate new closures for the found and not-found functions that pass in
    # the relevant function name.
    my $return = 1;
    for my $function (@{$functions_ref}) {
        my $found_ref    = sub { $func_found_ref->($function) };
        my $notfound_ref = sub { $user_notfound_ref->($function) };
        $return &= check_func($self, $function, $found_ref, $notfound_ref);
    }
    return $return;
}

# Returns C code that includes the given headers.  Used to construct prologues
# for check functions.
#
# @headers - The headers to include
#
# Returns: C source as a string that includes those headers
sub include {
    my @headers = @_;
    my $result  = q{};
    for my $header (@headers) {
        $result .= "#include <$header>\n";
    }
    return $result;
}

# Probes the C compilation environment for the information required to build
# the embedded libkafs compatibility layer.  This should be a Perl equivalent
# of the m4/kafs.m4 Autoconf macros from rra-c-util, plus the additional
# probes needed for the compatibility layer for building the cod.  Writes the
# results to glue/config.h and returns a list of extra C files to add to the
# module build.
#
# $build - The module build object, used to add additional libraries
#
# Returns: List of extra directories to add to the module build
#  Throws: Text exception if the module cannot be built in this environment
sub config_kafs {
    my ($build) = @_;
    my $config = Config::AutoConf->new;

    # Checks needed for the generic portability layer.
    $config->check_default_headers;
    if (!$config->check_header('stdbool.h')) {
        $config->check_type('_Bool');
    }
    $config->check_type('sig_atomic_t', undef, undef,
        include(qw(sys/types.h signal.h)));
    $config->check_type('ssize_t', undef, undef, include('sys/types.h'));

    # Checks needed by all libkafs code.
    $config->check_header('sys/ioccom.h');

    # If the user passed extra flags into Build.PL, use them for probes.
    if ($build->extra_linker_flags) {
        my $flags = $build->extra_linker_flags;
        my @flags = ref($flags) ? @{$flags} : ($flags);
        $config->push_link_flags(@flags);
    }

    # Check if we have a library available to us.  If so, check whether it
    # provides k_pioctl and k_haspag and then return.
    my $lib = $config->search_libs('k_hasafs', ['kafs', 'kopenafs']);
    my @files;
    if ($lib) {
        $config->define_var('HAVE_K_HASAFS', 1,
            'Define to 1 if you have the k_hasafs function.');
        my $flags = $build->extra_linker_flags;
        my @flags = ref($flags) ? @{$flags} : ($flags);
        $build->extra_linker_flags(@flags, '-l' . $lib);
        if ($lib eq 'kafs') {
            $config->check_header('kafs.h');
        } elsif ($lib eq 'kopenafs') {
            $config->check_header('kopenafs.h');
        }
        check_funcs($config, ['k_pioctl']);
        if (!check_funcs($config, ['k_haspag'])) {
            @files = qw(portable/k_haspag.c);
        }
    } else {
        @files = qw(kafs/kafs.c portable/k_haspag.c);
        $config->define_var('HAVE_KAFS_REPLACEMENT', 1,
            'Define to 1 if the libkafs replacement is built.');
        $config->define_var('HAVE_KAFS_LINUX', 1,
            'Define to 1 to use the Linux AFS /proc interface.');
    }

    # Write out the configuration.
    $config->write_config_h('glue/config.h');

    # Return the list of files to add to the build.
    return @files;
}

# Basic package configuration.
my $build = Module::Build->new(
    module_name          => 'AFS::PAG',
    dist_version_from    => 'lib/AFS/PAG.pm',
    dist_author          => 'Russ Allbery <rra@cpan.org>',
    license              => 'mit',
    recursive_test_files => 1,
    add_to_cleanup       => [qw(config.log cover_db glue/*.o)],

    # XS configuration.
    c_source             => 'glue',
    extra_compiler_flags => ['-I.'],

    # Additional package metadata.
    meta_merge => {
        resources => {
            repository => 'git://git.eyrie.org/afs/afs-pag.git',
            bugtracker =>
              'https://rt.cpan.org/Public/Dist/Display.html?Name=AFS-PAG',
        },
    },

    # Other package relationships.
    configure_requires => {
        'Config::AutoConf' => 0,
        'Module::Build'    => '0.28',
        autodie            => 0,
        perl               => '5.010',
    },
    requires => {
        autodie => 0,
        perl    => '5.010',
    },
);

# Create the directory that will be used for config.h and stub files.
remove_tree('glue');
mkdir('glue');

# Write out the config.h file and get the list of files to add to the build.
my @c_files = config_kafs($build);

# We can't just add the C source files directly to the build for a couple of
# reasons.  First, Perl ships its own config.h, so we need to be sure we
# include our own instead of Perl's before building any source, since all of
# the files (copied from rra-c-util, so we don't want to change them) include
# config.h as the first action.  Second, Module::Build can only handle one
# directory of supplemental source files.
#
# We deal with both of these issues by creating stub files in a subdirectory
# named glue that include glue/config.h and then the actual C source file.
for my $file (@c_files) {
    my $glue_file = File::Spec->catfile('glue', basename($file));
    open(my $wrapper, '>', $glue_file);
    say {$wrapper} '#include <glue/config.h>'
      or die "Cannot write to $glue_file: $!\n";
    say {$wrapper} "#include <$file>"
      or die "Cannot write to $glue_file: $!\n";
    close($wrapper);
}

# Generate the build script.
$build->create_build_script;

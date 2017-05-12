# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

package Clownfish::CFC::Perl::Build::Charmonic;

use base qw( Module::Build );

our $VERSION = '0.006001';
$VERSION = eval $VERSION;

use Carp;
use Config;
use Cwd qw( getcwd );
use File::Spec::Functions qw( catfile curdir );

# Add a custom Module::Build hashref property to pass the following build
# parameters.
# charmonizer_c: Charmonizer C file, required
# create_makefile: Whether to create a Makefile.
# make_options: Options passed to make.
if ( $Module::Build::VERSION <= 0.30 ) {
    __PACKAGE__->add_property( charmonizer_params => {} );
}
else {
    __PACKAGE__->add_property(
        'charmonizer_params',
        default => {},
    );
}

my $CHARMONIZER_EXE_PATH = catfile( curdir(), "charmonizer$Config{_exe}" );
my $CHARMONY_H_PATH      = 'charmony.h';
my $CHARMONY_PM_PATH     = 'Charmony.pm';

# Compile and run the charmonizer executable, creating the charmony.h and
# Charmony.pm files.
sub ACTION_charmony {
    my $self = shift;

    my $cc              = $self->config('cc');
    my $is_msvc         = lc($cc) =~ /^cl\b/;
    my $charmonizer_c   = $self->charmonizer_params('charmonizer_c');
    my $create_makefile = $self->charmonizer_params('create_makefile');

    $self->add_to_cleanup($CHARMONIZER_EXE_PATH);
    if ( !$self->up_to_date( $charmonizer_c, $CHARMONIZER_EXE_PATH ) ) {
        print "\nCompiling $CHARMONIZER_EXE_PATH...\n\n";
        my @command = ( $self->split_like_shell($cc), $charmonizer_c );
        if ($is_msvc) {
            push @command, "/Fe$CHARMONIZER_EXE_PATH";
        }
        else {
            push @command, '-o', $CHARMONIZER_EXE_PATH;
        }
        system @command
            and die "Failed to compile $CHARMONIZER_EXE_PATH";
    }

    my @derived_files = ( $CHARMONY_H_PATH, $CHARMONY_PM_PATH );
    push @derived_files, 'Makefile' if $create_makefile;
    return if $self->up_to_date( $CHARMONIZER_EXE_PATH, \@derived_files );
    print "\nRunning $CHARMONIZER_EXE_PATH...\n\n";

    $self->add_to_cleanup($CHARMONY_H_PATH);
    $self->add_to_cleanup($CHARMONY_PM_PATH);
    # Clean up after charmonizer if it doesn't succeed on its own.
    $self->add_to_cleanup("_charm*");

    if ($is_msvc) {
        $self->add_to_cleanup('charmonizer.obj');
    }

    # Prepare arguments to charmonizer.
    my @command = (
        $CHARMONIZER_EXE_PATH,
        "--cc=$cc",  # May contain spaces and args.
        '--host=perl',
        '--enable-c',
        '--enable-perl',
    );
    if ($create_makefile) {
        push @command,
             '--make=' . $self->config('make'),
             '--enable-makefile';
        $self->add_to_cleanup('Makefile');
    }
    # Perl 5.8.7 added support for CLONE_SKIP.
    # Thread support in 5.10.0 seems completely broken (CLOWNFISH-107).
    if ( !$self->config('usethreads') || $^V lt v5.8.7 || $^V eq v5.10.0 ) {
        push @command, '--disable-threads';
    }
    push @command, (
        '--', $self->config('ccflags'),
        '-I' . File::Spec->catdir($self->config('archlibexp'), 'CORE'),
    );
    if ( $ENV{CHARM_VALGRIND} ) {
        unshift @command, "valgrind", "--leak-check=yes";
    }
    print join( " ", @command ), $/;

    if ( system(@command) != 0 ) {
        warn "Failed to run $CHARMONIZER_EXE_PATH: $!\n";

        if ( ( $ENV{CHARM_VERBOSITY} || 0 ) < 2 ) {
            print "Rerunning $CHARMONIZER_EXE_PATH with CHARM_VERBOSITY=2\n\n";
            $ENV{CHARM_VERBOSITY} = 2;
            system(@command);
        }

        die "Aborted";
    }
}

my $config;

sub charmony {
    my ( undef, $key ) = @_;
    if (!$config) {
        eval { require 'Charmony.pm'; };
        if ( !$@ ) {
            $config = Charmony->config;
        }
    }
    if ($config) {
        return $config->{$key};
    }
    return;
}

sub cf_make_objects {
    my ( $self, $target ) = @_;

    return [] unless $self->charmonizer_params('create_makefile');

    $self->_cf_charm_run_make(lc($target));

    return [ split( /\s+/, $self->charmony(uc($target)) ) ];
}

sub cf_make_clean {
    my $self = shift;

    return unless $self->charmonizer_params('create_makefile')
                  && -e 'Makefile';

    $self->_cf_charm_run_make('clean');
}

sub _cf_charm_run_make {
    my ( $self, $target ) = @_;

    my $make_options = $self->charmonizer_params('make_options');
    my @command = (
        $self->config('make'),
        $self->split_like_shell($make_options),
        $target,
    );
    print join(' ', @command), "\n";
    system @command and die($self->config('make') . " failed");
}

1;

__END__

package Arepa::BuilderFarm;

use strict;
use warnings;

use Carp qw(croak);
use Cwd;
use File::Temp;

use Arepa::Config;
use Arepa::PackageDb;

sub new {
    my ($class, $config_path, %user_opts) = @_;

    my $config = Arepa::Config->new($config_path, %user_opts);
    my $self = bless {
        config_path => $config_path,
        config      => $config,
        package_db  => Arepa::PackageDb->new($config->get_key('package_db')),
        last_build_log => undef,
    }, $class;

    return $self;
}

sub last_build_log {
    my ($self) = @_;
    return $self->{last_build_log};
}

sub package_db {
    my ($self) = @_;
    return $self->{package_db};
}

sub get_builder_config {
    my ($self, $builder) = @_;
    return $self->{config}->get_builder_config($builder);
}

sub builder_type_module {
    my ($self, $type) = @_;
    $type =~ s/[^a-z0-9]//goi;
    return "Arepa::Builder::" . ucfirst(lc($type));
}

sub builder_module {
    my ($self, $builder_name) = @_;
    my %conf = $self->get_builder_config($builder_name);
    my $module = $self->builder_type_module($conf{type});
    eval "use $module;";
    if ($@) {
        croak "Couldn't load builder module '$module' for type '$conf{type}': $@";
    }
    return $module;
}

sub builder {
    my ($self, $builder_name) = @_;

    my $module_name = $self->builder_module($builder_name);
    return $module_name->new($self->get_builder_config($builder_name));
}

sub init_builders {
    my ($self) = @_;

    foreach my $builder ($self->{config}->get_builders) {
        $self->init_builder($builder);
    }
}

sub init_builder {
    my ($self, $builder) = @_;

    my $module = $self->builder_module($builder);
    $module->init($builder);
}

sub uninit_builders {
    my ($self) = @_;

    foreach my $builder ($self->{config}->get_builders) {
        $self->uninit_builder($builder);
    }
}

sub uninit_builder {
    my ($self, $builder) = @_;

    my $module = $self->builder_module($builder);
    $module->uninit($builder);
}

sub compile_package_from_dsc {
    my ($self, $builder_name, $dsc_file, %user_opts) = @_;
    my %opts = (output_dir => '.', %user_opts);

    my $builder = $self->builder_module($builder_name);
    my $r = $builder->compile_package_from_dsc($dsc_file, %opts);
    $self->{last_build_log} = $builder->last_build_log;
    return $r;
}

sub bin_nmu_id {
    my ($self, $source_pkg_attrs, $builder) = @_;

    my %builder_cfg = $self->{config}->get_builder_config($builder);
    my $r = scalar grep { $_ eq $source_pkg_attrs->{distribution} }
                        @{$builder_cfg{bin_nmu_for} || []};
    if ($r) {
        # NOTE: This bin_nmu_id thing is explicitly UNSUPPORTED. I'm not sure I
        # want to go down that path, but it _may_ prove useful. So I'm leaving
        # these two lines here while I make my mind. When/if I decide that it's
        # a good idea, I'll add tests and document it.
        if (exists $builder_cfg{bin_nmu_id}) {
            return $builder_cfg{bin_nmu_id};
        }
        else {
            my @builders = $self->{config}->get_builders;
            for (my $i = 0; $i < scalar @builders; ++$i) {
                return $i+1 if $builders[$i] eq $builder;
            }
            croak "Can't find builder '$builder'?!\n";
        }
    }
    else {
        return undef;
    }
}

sub compile_package_from_queue {
    my ($self, $builder_name, $request_id, %user_opts) = @_;
    my %opts = (output_dir => '.', %user_opts);

    my %request = $self->package_db->get_compilation_request_by_id($request_id);
    $self->package_db->mark_compilation_started($request_id, $builder_name);

    my $builder = $self->builder($builder_name);
    my %source_attrs = $self->package_db->get_source_package_by_id($request{source_package_id});
    $opts{bin_nmu} = $self->bin_nmu_id(\%source_attrs, $builder_name);
    my $r =
        $builder->compile_package_from_repository($source_attrs{name},
                                                  $source_attrs{full_version},
                                                  %opts);
    $self->{last_build_log} = $builder->last_build_log;

    # Save the build log
    my $build_log_dir = $self->{config}->get_key('dir:build_logs');
    my $build_log_path = File::Spec->catfile($build_log_dir,
                                             $request_id);
    open F, ">$build_log_path" or croak "Can't write in $build_log_path";
    print F $self->{last_build_log};
    close F;

    # Mark the compilation request appropriately
    if ($r) {
        $self->package_db->mark_compilation_completed($request_id);
    }
    else {
        $self->package_db->mark_compilation_failed($request_id);
    }
    return $r;
}

sub request_package_compilation {
    my ($self, $source_id) = @_;

    foreach my $target ($self->get_compilation_targets($source_id)) {
        my ($arch, $dist) = @$target;
        $self->{package_db}->request_compilation($source_id, $arch, $dist);
    }
}

sub get_compilation_targets {
    my ($self, $source_id) = @_;

    my %source_attrs = $self->{package_db}->get_source_package_by_id($source_id);
    my @builders = $self->get_matching_builders($source_attrs{architecture},
                                                $source_attrs{distribution});
    return map {
               my %builder_config = $self->{config}->get_builder_config($_);
               $source_attrs{architecture} eq 'any' ?
                   [$builder_config{architecture},
                    $builder_config{distribution}]  :
                   [$source_attrs  {architecture},
                    $builder_config{distribution}];
           } @builders;
}

sub get_matching_builders {
    my ($self, $arch, $distro) = @_;

    # Get the builder information once
    my @builder_information = map { { $self->{config}->get_builder_config($_) } }
                                  $self->{config}->get_builders;

    # Get builders that match *both*:
    return map {
                $_->{name}
           }
           # 1) the architecture in 'architecture' (or 'all' if applicable)
           grep {
               ($arch eq 'any'                            ||
                $arch eq $_->{architecture}               ||
                ($arch eq 'all' && $_->{architecture_all}));
           }
           # 2) the $distro in *either* 'distribution' or
           #    'distribution_aliases'
           grep {
               my @bdistros = ref($_->{distribution_aliases}) eq 'ARRAY' ?
                                   @{$_->{distribution_aliases}} :
                                   $_->{distribution_aliases};
               my @binnmu_distros = ref($_->{bin_nmu_for}) eq 'ARRAY' ?
                                                 @{$_->{bin_nmu_for}} :
                                                 ($_->{bin_nmu_for} || ());

               $distro eq $_->{distribution} ||
                   grep({ $distro eq $_ } @bdistros) ||
                   grep({ $distro eq $_ } @binnmu_distros);
           }
           @builder_information;
}

sub register_source_package {
    my ($self, %source_attrs) = @_;

    my $pdb = $self->package_db;
    my $source_id = $pdb->get_source_package_id($source_attrs{name},
                                                $source_attrs{full_version});
    if (!defined $source_id) {
        $source_id = $pdb->insert_source_package(%source_attrs);
    }
    return $source_id;
}

sub canonical_distribution {
    my ($self, $arch, $distribution) = @_;

    my @builders = $self->get_matching_builders($arch, $distribution);
    my $distro;
    foreach my $b (@builders) {
        my %builder_cfg = $self->{config}->get_builder_config($b);
        if (grep { $_ eq $distribution }
                 @{$builder_cfg{distribution_aliases}},
                 $builder_cfg{distribution}) {
            # There should be only one; if there's more than one, that's a
            # problem
            if ($distro) {
                croak "There is more than one builder that " .
                        "specifies '$distribution' as alias. " .
                        "That's not correct! One of them " .
                        "should specify it as bin_nmu_for";
            }
            $distro = $builder_cfg{distribution};
        }
    }
    return $distro;
}

1;

__END__

=head1 NAME

Arepa::BuilderFarm - Arepa builder farm access class

=head1 SYNOPSIS

 my $repo = Arepa::BuilderFarm->new('path/to/config.yml');
 my $repo = Arepa::BuilderFarm->new('path/to/config.yml',
                                    builder_config_dir =>
                                                    'path/to/builderconf');
 $repo->last_build_log;
 $repo->package_db;

 my %config = $repo->get_builder_config($builder_name);
 my $module_name = $repo->builder_type_module($type);
 my $module_name = $repo->builder_module($builder_name);
 my $builder     = $repo->builder($builder_name);

 $repo->init_builders;
 $repo->init_builder($builder_name);
 $repo->uninit_builders;
 $repo->uninit_builder($builder_name);

 my $r = $repo->compile_package_from_dsc($builder_name,
                                         $dsc_file,
                                         %opts);
 my $r = $repo->compile_package_from_queue($builder_name,
                                           $request_id,
                                           %opts);

 $repo->request_package_compilation($source_id);
 my @arch_distro_pairs = $repo->get_compilation_targets($source_id);
 my @builders = $repo->get_matching_builders($architecture,
                                             $distribution);

 my $source_id = $repo->register_source_package(%source_package_attrs);

=head1 DESCRIPTION

This class gives access to the "builder farm", to actions like initialising the
builders, compiling packages and calculating which builders should compile
which packages.

The builder farm uses the Arepa configuration to get the needed information.

=head1 METHODS

=over 4

=item new($path)

=item new($path, %options)

Creates a new builder farm access object, using the configuration file in
C<$path>. The only valid option is C<builder_config_dir> (see L<Arepa::Config>
documentation for details).

=item last_build_log

Returns the output of the last compilation attempt.

=item package_db

Returns a C<Arepa::PackageDb> object pointing to the package database used by
the builder farm.

=item get_builder_config($builder_name)

Returns a hash with the configuration for the builder C<$builder_name>.

=item builder_type_module($type)

Returns the module name implementing the features for the builder type
C<$type>.

=item builder_module($builder_name)

Returns the module name implementing the features for the given
C<$builder_name>.

=item builder($builder_name)

Returns the builder object identified by C<$builder_name>.

=item init_builders

Initialises all the builders. It should be called once per machine boot (e.g.
inside an init script).

=item init_builder($builder_name)

Initialises the builder C<$builder_name>.

=item uninit_builders

Uninitialises all the builders. It should be called once per machine shutdown
(e.g. inside an init script).

=item uninit_builder($builder_name)

Uninitialises the builder C<$builder_name>.

=item compile_package_from_dsc($builder_name, $dsc_file, %opts)

Compiles the source package described by the C<.dsc> file C<$dsc_file> using
the builder C<$builder_name>, and puts the resulting C<.deb> files in the
appropriate output directory. You can specify it with the C<output_dir> option
in C<%opts>. If no directory is specified, they're left in the current
directory.

=item bin_nmu_id($src_pkg_attrs, $builder_name)

Returns the binary NMU id that C<$builder_name> should use when building the
given source package. The first parameter, C<$src_pkg_attrs>, is a hashref with
the attributes of the source package (see C<get_source_package_by_id> in
L<Arepa::PackageDb>). The binNMU id is a number, or C<undef> if the given
builder should not build the given source package as a binNMU.

=item compile_package_from_queue($builder_name, $request_id, %opts)

Compiles the request C<$request_id> using the builder C<$builder_name>, and
puts the resulting C<.deb> files in the output directory (by default, the
current directory). The only valid option is C<output_dir> (to change the
output directory).

=item request_package_compilation($source_id)

Adds a compilation request for the source package with id C<$source_id>.

=item get_compilation_targets($source_id)

Returns an array of targets for the given source package C<$source_id>. Each
target is an arrayref with two elements: architecture and distribution.

=item get_matching_builders($architecture, $distribution)

Gets the builders that should compile packages for the given C<$architecture>
and C<$distribution>. It returns a list of builder names.

=item register_source_package(%source_package_attrs)

Registers the source package with the given C<%source_package_attrs>. This
method is seldom used, as you would normally add the source package to the
repository first (using C<Arepa::Repository>), which automatically registers
the source package.

=item canonical_distribution($arch, $distro)

Calculates the canonical distribution, ie. the distribution as registered by
one of the Arepa builders, given an architecture and distribution from a
changes file or similar. It's needed for the reprepro call.  If reprepro
accepted "reprepro includesrc 'funnydistro' ...", having 'funnydistro' in the
AlsoAcceptFor list, this wouldn't be necessary.

=back

=head1 SEE ALSO

C<Arepa::Repository>, C<Arepa::PackageDb>, C<Arepa::Config>.

=head1 AUTHOR

Esteban Manchado Velázquez <estebanm@opera.com>.

=head1 LICENSE AND COPYRIGHT

This code is offered under the Open Source BSD license.

Copyright (c) 2010, Opera Software. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item

Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

=item

Neither the name of Opera Software nor the names of its contributors may
be used to endorse or promote products derived from this software without
specific prior written permission.

=back

=head1 DISCLAIMER OF WARRANTY

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package Arepa::Builder;

use strict;
use warnings;

use Carp;
use Cwd;
use File::chmod;
use File::Temp;
use File::Basename;
use File::Path;
use File::Find;
use File::Copy;
use Config::Tiny;
use YAML::Syck;

use Arepa;

my $ui_module = 'Arepa::UI::Text';

sub ui_module {
    my ($self, $module) = @_;
    if (defined $module) {
        $ui_module = $module;
    }
    eval qq(use $ui_module;);
    die $@ if $@;
    return $ui_module;
}

sub type {
    my ($self) = @_;
    my $class = ref($self) || $self;
    $class =~ s/.+:://;
    if (!$class) {
        croak "You should use a proper builder class, not ".ref($self);
    }
    return lc($class);
}

sub new {
    my ($class, %attrs) = @_;

    return bless {
                    %attrs,
                 },
                 $class;
}

sub name { $_[0]->{name} }
sub last_build_log { $_[0]->{last_build_log} }

sub config {
    my ($self, $key) = @_;
    return $self->{$key};
}


# To be implemented by each type

sub do_init {
    my ($self, $builder) = @_;
    croak "Not implemented";
}

sub init {
    my ($self, $builder) = @_;
    $self->do_init($builder);
}

sub do_uninit {
    my ($self, $builder) = @_;
    croak "Not implemented";
}

sub uninit {
    my ($self, $builder) = @_;
    $self->do_uninit($builder);
}

sub do_compile_package_from_dsc {
    my ($self, $dsc_file, %user_opts) = @_;
    croak "Not implemented";
}

sub compile_package_from_dsc {
    my ($self, $dsc_file, %user_opts) = @_;
    $self->do_compile_package_from_dsc($dsc_file, %user_opts);
}

sub do_compile_package_from_repository {
    my ($self, $pkg_name, $pkg_version, %user_opts) = @_;
    croak "Not implemented";
}

sub compile_package_from_repository {
    my ($self, $pkg_name, $pkg_version, %user_opts) = @_;
    $self->do_compile_package_from_repository($pkg_name,
                                              $pkg_version,
                                              %user_opts);
}

sub do_create {
    my ($self, $builder_dir, $mirror, $distribution, %opts) = @_;
    croak "Not implemented";
}

sub create {
    my ($self, $builder_dir, $mirror, $distribution, %user_opts) = @_;
    my %opts = (builder_config_dir => '/etc/arepa/builders',
                arch               => `dpkg-architecture -qDEB_BUILD_ARCH`,
                %user_opts);
    chomp($opts{arch});

    $self->do_create($builder_dir, $mirror, $distribution, %opts);

    $self->ui_module->print_title("Configuration for config.yml");

    my $type = $self->type;

    my $config_string = <<EOD;
type: $type
architecture: $opts{arch}
# Compile "Architecture: all" packages with this builder?
architecture_all: 0
# This is the distribution the packages compiled by this builder go to. For a
# package to be compiled by this builder, it has to have the correct
# architecture and this distribution (or an alias or similar, see below) in
# its *.changes file.
distribution: $distribution
# Other names for this distribution (if the distribution name is
# mycompany-squeeze, you might want 'squeeze' and 'testing' as aliases)
distribution_aliases: []
# Recompile packages (binNMU or Binary-only Non-Maintainer Upload; see
# http://www.debian.org/doc/developers-reference/pkgs.html#nmu-binnmu)
# originally uploaded for other distributions in this builder. This option is
# an easy way to get "for free" packages compiled for several distributions.
# Typical values for this list would be 'unstable' or 'lenny'
bin_nmu_for: []
EOD

    my $builder_name = basename($builder_dir);
    my $path = File::Spec->catfile($opts{builder_config_dir},
                                   "$builder_name.yml");
    open F, ">$path" or croak "Can't write builder configuration in $path";
    print F $config_string;
    close F;

    my $sources_list_path = File::Spec->catfile($builder_dir, "etc", "apt",
                                                "sources.list");

    $self->ui_module->print_title("Done");
    print <<EOM

Next steps
----------
* Tweak the builder configuration in $path
* Review $sources_list_path
* Add all relevant repository keys to the builder (eg. "apt-key add ...")

EOM
}

1;

__END__

=head1 NAME

Arepa::Builder - Arepa builder base "class"

=head1 SYNOPSIS

 my $module = Arepa::Builder->ui_module;
 Arepa::Builder->ui_module($new_ui_module);

 Arepa::Builder->init($builder_name);

 Arepa::Builder->compile_package_from_dsc($builder_name, $dsc_file);
 Arepa::Builder->compile_package_from_dsc($builder_name, $dsc_file,
                                          output_dir => 1);
 Arepa::Builder->compile_package_from_repository($builder_name,
                                                 $dsc_file);
 Arepa::Builder->compile_package_from_repository($builder_name,
                                                 $dsc_file,
                                                 output_dir => 1,
                                                 bin_nmu    => 1);

 my $log = Arepa::Builder->last_build_log;

 Arepa::Builder->create($builder_dir, $mirror, $distribution);

=head1 DESCRIPTION

This module contains the interface for an Arepa builder. It should be the
"subclass" for any builder module. Every Arepa builder type must have a module
implementing this API. C<Arepa::BuilderFarm>, when manipulating the builders,
will use the correct builder module according to the builder type (e.g. for
type 'sbuild', C<Arepa::Builder::Sbuild>).

This module is never used directly, but through "subclasses" in
C<Arepa::BuilderFarm>.

=head1 METHODS

=over 4

=item ui_module

=item ui_module($ui_module)

Returns the UI module being used (by default, C<Arepa::UI::Text>. If a
parameter is passed, the UI module is changed to that, and the new value is
returned.

=item init($builder_name)

Initialises the given C<$builder_name> to be able to use it. This should be
done once per machine boot (e.g. in an init script).

=item compile_package_from_dsc($builder_name, $dsc_file)

=item compile_package_from_dsc($builder_name, $dsc_file, %opts)

Compiles the source package described by the given C<$dsc_file> using the given
C<$builder_name>. The resulting C<.deb> files are put in the current directory
by default. Valid options are C<output_dir> and C<bin_nmu> (see
L<compile_package_from_repository> documentation).

=item compile_package_from_repository($builder_name, $name, $version)

=item compile_package_from_repository($builder_name, $name, $version, %opts)

Compiles the source package with the given C<$name> and C<$version> using the
given C<$builder_name>. By default, the resulting C<.deb> files are put in the
current directory. The only valid options are C<output_dir> (to specify the
directory where the resulting C<.deb> files should end up in) and C<bin_nmu>
(to specify if the compilation should be considered a binNMU).

=item last_build_log

Returns the log text of the last build.

=item create($builder_dir, $mirror, $distribution);

Creates a new builder in the given directory C<$builder_dir>, using the Debian
mirror C<$mirror> and the distribution C<$distribution>.

=back

=head1 SEE ALSO

C<Arepa::BuilderFarm>, C<Arepa::Config>.

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

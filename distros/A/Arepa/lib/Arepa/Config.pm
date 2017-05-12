package Arepa::Config;

use Carp qw(croak);
use File::Basename;
use File::Spec;
use YAML::Syck;

sub new {
    my ($class, $path, %user_opts) = @_;
    my %opts = (builder_config_dir => File::Spec->catfile(dirname($path),
                                                          'builders'),
                %user_opts);

    my $self = bless {
        config => LoadFile($path),
    }, $class;

    # Now, load the builder configuration
    opendir D, $opts{builder_config_dir} or
            croak "Can't read directory $opts{builder_config_dir}";
    my @builder_config_files = grep /\.yml$/, readdir D;
    closedir D;
    $self->{config}->{builders} = [];
    foreach my $file (@builder_config_files) {
        my $name = $file;
        $name =~ s/\.yml$//;
        my $path = File::Spec->catfile($opts{builder_config_dir}, $file);
        my $builder_conf = LoadFile($path);
        push @{$self->{config}->{builders}}, {%$builder_conf,
                                              name => $name};
    }

    return $self;
}

sub key_exists {
    my ($self, $key) = @_;
    my $exists = 0;

    # If get_key dies, the key doesn't exist
    eval {
        $self->get_key($key);
        $exists = 1;
    };

    return $exists;
}

sub get_key {
    my ($self, $key) = @_;

    my @keys = split(':', $key);
    my $value = $self->{config};
    foreach my $k (@keys) {
        if (defined $value->{$k}) {
            $value = $value->{$k};
        }
        else {
            croak "Can't find configuration key $key (no $k)";
        }
    }
    return $value;
}

sub get_builders {
    my ($self, %user_opts) = @_;
    my %opts = (%user_opts);

    my @builders = @{$self->{config}->{builders}};
    if (exists $opts{type}) {
        @builders = grep { $_->{type} eq $opts{type} }
                         @builders;
    }
    return map { $_->{name} } @builders;
}

sub get_builder_config {
    my ($self, $builder_name) = @_;

    my $builder_config = $self->{config}->{builders};
    my @matching_builders = grep { $_->{name} eq $builder_name }
                                 @$builder_config;
    scalar(@matching_builders) == 0 and
        croak "Don't know builder '$builder_name'";
    scalar(@matching_builders) >  1 and
        croak "There is more than one builder called '$builder_name'";
    return %{$matching_builders[0]};
}

sub get_builder_config_key {
    my ($self, $builder_name, $config_key) = @_;

    my %builder_config = $self->get_builder_config($builder_name);
    defined($builder_config{$config_key}) or
        croak "'$builder_name' doesn't have a configuration key $config_key";
    return $builder_config{$config_key};
}

1;

__END__

=head1 NAME

Arepa::Config - Arepa package database API

=head1 SYNOPSIS

 my $config = Arepa::Config->new('path/to/config.yml');
 my $config = Arepa::Config->new('path/to/config.yml',
                                 builder_config_dir => 'path/to/builderconf');

 my $pdb_path = $config->get_key('package_db');
 my $repo_path = $config->get_key('repository:path');
 if ($config->key_exists('optional:key')) {
     $value = $config->get_key('optional:key');
 }

 my @builder_names = $config->get_builders;
 my %builder_config = $config->get_builder_config('some-builder');
 my $value = $config->get_builder_config_key('some-builder', $key);

=head1 DESCRIPTION

This class allows easy access to the Arepa configuration. The configuration is
divided in two parts: the basic configuration (a single YAML file) and the
configuration for the builders (a YAML file for each builder). Typically you
would pass a single path for the main configuration, and the builder
configuration would be loaded from the directory C<builders> inside the same
parent directory as the main configuration file. However, if you want you can
specify a custom directory to load the builder configuration from.

This is an excerpt of an example configuration file:

 ---
 repository:
   path: /home/zoso/src/apt-web/test-repo/
 upload_queue:
   path: /home/zoso/src/apt-web/incoming
 package_db: /home/zoso/src/apt-web/package.db
 web_ui:
   base_url: http://localhost
   user_file: /home/zoso/src/apt-web/repo-tools-web/users.yml

This is an example of a builder configuration file (say, C<squeeze32.yaml>):

 ---
 type: sbuild
 architecture: i386
 distribution: my-squeeze
 other_distributions: [squeeze, unstable]

Usually this class is not used directly, but internally in C<Arepa::Repository>
or C<Arepa::BuilderFarm>.

=head1 METHODS

=over 4

=item new($path)

=item new($path, %options)

It creates a new configuration access object for the configuration file in the
given C<$path>. The only valid option is C<builder_config_dir>, the path where
the builder configuration files are located.

=item key_exists($key)

Return true/false if the given configuration key is defined or not.

=item get_key($key)

Returns the value of the given C<$key> in the configuration file. If it's not a
top-level key, the subkeys must be separated by a colon ("C<:>"). If the key
cannot be found, an exception is thrown.

=item get_builders

Returns an array of names of the defined builders.

=item get_builder_config($builder_name)

Returns a hash with the configuration of the given C<$builder_name>. If no
builder (or more than one) is found by that name, an exception is thrown.

=item get_builder_config_key($builder_name, $key)

Returns the value for the given configuration C<$key> for the given
C<$builder_name>.

=back

=head1 SEE ALSO

C<Arepa::BuilderFarm>, C<Arepa::Repository>.

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

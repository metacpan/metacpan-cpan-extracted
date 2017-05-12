package Arepa::Repository;

use strict;
use warnings;

use Carp qw(croak);
use IO::Zlib;

use Parse::Debian::PackageDesc;
use Arepa::Config;
use Arepa::PackageDb;

sub new {
    my ($class, $config_path) = @_;

    my $config = Arepa::Config->new($config_path);
    my $self = bless {
        config_path => $config_path,
        config      => $config,
        package_db  => Arepa::PackageDb->new($config->get_key('package_db')),
    }, $class;

    return $self;
}

sub config_key_exists {
    my ($self, $key) = @_;
    return $self->{config}->key_exists($key);
}

sub get_config_key {
    my ($self, $key) = @_;
    return $self->{config}->get_key($key);
}

sub get_distributions {
    my ($self) = @_;

    my $repository_config_file = $self->get_config_key('repository:path');
    my $distributions_config_file = "$repository_config_file/conf/distributions";
    open F, $distributions_config_file or croak "Can't open configuration file ";
    my ($line, $repo_attrs, @repos);
    while ($line = <F>) {
        if ($line =~ /^\s*$/) {
            push @repos, $repo_attrs if (ref($repo_attrs) && %$repo_attrs);
            $repo_attrs = {};
        }
        elsif ($line =~ /^([^:]+):\s+(.+)/i) {
            $repo_attrs->{lc($1)} = $2;
        }
    }
    push @repos, $repo_attrs if (ref($repo_attrs) && %$repo_attrs);
    close F;
    return @repos;
}

sub get_architectures {
    my ($self) = @_;

    my @archs;
    foreach my $repo ($self->get_distributions) {
        foreach my $arch (split(/\s+/, $repo->{architectures})) {
            push @archs, $arch unless grep { $arch eq $_ }
                                           @archs;
        }
    }
    return @archs;
}

sub insert_source_package {
    my ($self, $dsc_file, $distro, %user_opts) = @_;

    use Parse::Debian::PackageDesc;
    my $parsed_dsc = Parse::Debian::PackageDesc->new($dsc_file);
    my @archs = $parsed_dsc->architecture;
    my $arch  = (scalar @archs > 1) ? 'any' : $archs[0];
    my %args = (name         => $parsed_dsc->name,
                full_version => $parsed_dsc->version,
                architecture => $arch,
                distribution => $distro);

    if (exists $user_opts{comments}) {
        $args{comments} = $user_opts{comments};
        delete $user_opts{comments};
    }

    my $canonical_distro = $distro;
    if ($user_opts{canonical_distro}) {
        $canonical_distro = $user_opts{canonical_distro};
        delete $user_opts{canonical_distro};
    }

    my $r = $self->_execute_reprepro('includedsc',
                                     $canonical_distro,
                                     $dsc_file,
                                     %user_opts);
    if ($r) {
        return $self->{package_db}->insert_source_package(%args);
    }
    else {
        return 0;
    }
}

sub insert_binary_package {
    my ($self, $deb_file, $distro) = @_;

    return $self->_execute_reprepro('includedeb',
                                    $distro,
                                    $deb_file);
}

sub _shell_escape {
    my ($self, $arg) = @_;
    if (defined $arg) {
        $arg =~ s/'/\\'/go;
        return "'$arg'";
    }

    return "";
}

sub last_cmd_output {
    my ($self) = @_;
    $self->{last_cmd_output};
}

sub _execute_reprepro {
    my ($self, $mode, $distro, $file_path, %extra_args) = @_;

    my $repo_path = $self->get_config_key("repository:path");
    $mode      = $self->_shell_escape($mode);
    $distro    = $self->_shell_escape($distro);
    $file_path = $self->_shell_escape($file_path);
    # Extra arguments
    my $extra = "";
    foreach my $arg (keys %extra_args) {
        if ($arg eq 'section') {
            $extra .= " --section " . $self->_shell_escape($extra_args{$arg});
        }
        elsif ($arg eq 'priority') {
            $extra .= " --priority " . $self->_shell_escape($extra_args{$arg})
        }
        else {
            croak "Don't know anything about argument '$arg'";
        }
    }
    # GNUPG home directory
    if ($self->config_key_exists('web_ui:gpg_homedir')) {
        my $gpg_homedir = $self->get_config_key('web_ui:gpg_homedir');
        if (defined $gpg_homedir && $gpg_homedir) {
            $extra .= " --gnupghome '$gpg_homedir'";
        }
    }

    my $cmd = "reprepro -b$repo_path $extra $mode $distro $file_path 2>&1";
    my $umask = umask;
    umask($umask & 0707);           # Always allow group permissions
    $self->{last_cmd_output} = `$cmd`;
    my $status = $?;
    umask $umask;
    if ($status == 0) {
        return 1;
    }
    else {
        print STDERR "Reprepro command failed: '$cmd'\n";
        return 0;
    }
}

sub get_package_list {
    my ($self) = @_;

    my %pkg_list;
    my $repo_path = $self->get_config_key("repository:path");
    foreach my $codename (map { $_->{codename} } $self->get_distributions) {
        my $cmd = "reprepro -b$repo_path list $codename";
        open PIPE, "$cmd |";
        while (<PIPE>) {
            my ($distro, $comp, $arch, $pkg_name, $pkg_version) =
                /(.+)\|(.+)\|(.+): ([^ ]+) (.+)/;
            $pkg_list{$pkg_name}->{"$distro/$comp"}->{$pkg_version} ||= [];
            push @{$pkg_list{$pkg_name}->{"$distro/$comp"}->{$pkg_version}},
                 $arch;
        }
        close PIPE;
    }
    return %pkg_list;
}

sub get_source_package_information {
    my ($self, $package_name, $distro) = @_;

    my $repo_path = $self->get_config_key('repository:path');
    my $sources_file_path = File::Spec->catfile($repo_path,
                                                'dists',
                                                $distro,
                                                'main',
                                                'source',
                                                'Sources.gz');

    my $fh = new IO::Zlib;
    my $current_pkg = "";
    my %props;
    if ($fh->open($sources_file_path, "rb")) {
        while (<$fh>) {
            if (/^Package: (.+)/) {
                $current_pkg = $1;
            }
            elsif ($current_pkg eq $package_name) {
                if (/^([^:]+): (.+)/) {
                    $props{lc($1)} = $2;
                }
            }
        }
        $fh->close;
    }

    return %props;
}

sub get_binary_package_information {
    my ($self, $package_name, $distro, $arch) = @_;

    my $repo_path = $self->get_config_key('repository:path');
    my $packages_file_path = File::Spec->catfile($repo_path,
                                                 'dists',
                                                 $distro,
                                                 'main',
                                                 'binary-' . $arch,
                                                 'Packages');

    my $current_pkg = "";
    my %props;
    open F, $packages_file_path;
    while (<F>) {
        if (/^Package: (.+)/) {
            $current_pkg = $1;
        }
        elsif ($current_pkg eq $package_name) {
            if (/^([^:]+): (.+)/) {
                $props{lc($1)} = $2;
            }
        }
    }
    close F;

    return %props;
}

sub _all_names_for_distro {
    my ($self, %properties) = @_;

    my @aliases = ($properties{codename});
    if (defined $properties{suite}) {
        push @aliases, $properties{suite};
    }
    return @aliases;
}

sub add_distribution {
    my ($self, %properties) = @_;

    my $repository_path = $self->get_config_key('repository:path');
    my $distributions_config_file = "$repository_path/conf/distributions";


    if (! defined $properties{codename}) {
        return 0;
    }
    # Duplicate names of any kind
    my @new_distro_names = $self->_all_names_for_distro(%properties);
    my @existing_distro_names = map { $self->_all_names_for_distro(%$_) }
                                    $self->get_distributions;
    foreach my $distro_name (@new_distro_names) {
        if (grep { $_ eq $distro_name } @existing_distro_names) {
            return 0;
        }
    }

    # Everything seems alright, serialise the distribution properties
    my $serialised_distro = join("\n",
                                 map { ucfirst($_) . ": $properties{$_}"  }
                                     keys %properties);

    open F, ">>$distributions_config_file" or do {
        print STDERR "Can't open $distributions_config_file for writing\n";
        return 0;
    };
    print F <<EOD;

$serialised_distro
EOD
    close F;

    # Now, update the repository with the new distro
    $self->_execute_reprepro('export', $properties{codename});
}

sub sign_distribution {
    my ($self, $distro_name) = @_;

    my $repo_path = $self->get_config_key('repository:path');
    my $release_file_path = File::Spec->catfile($repo_path,
                                                "dists",
                                                $distro_name,
                                                "Release");
    unlink "$release_file_path.gpg";

    my $extra_options = "";
    if ($self->config_key_exists('repository:signature:id')) {
        my $key_id = $self->get_config_key('repository:signature:id');
        $extra_options = " -u $key_id";
    }
    my $gpg_cmd = "gpg --batch -abs $extra_options -o $release_file_path.gpg $release_file_path >/dev/null";

    return (system($gpg_cmd) == 0);
}

sub sync_remote {
    my ($self) = @_;

    my $repo_path = $self->get_config_key('repository:path');
    if ($self->config_key_exists('repository:remote_path')) {
        my $remote_repo_path = $self->get_config_key('repository:remote_path');
        my $rsync_cmd = "rsync -avz --delete $repo_path $remote_repo_path";
        if (system($rsync_cmd) == 0) {
            return 1;
        }
        else {
            print STDERR "Command was '$rsync_cmd'\n";
            return 0;
        }
    }
    return 0;
}

sub is_synced {
    my ($self) = @_;

    my $repo_path = $self->get_config_key('repository:path');
    if ($self->config_key_exists('repository:remote_path')) {
        my $remote_repo_path = $self->get_config_key('repository:remote_path');
        my $rsync_cmd = "rsync -avz --delete --dry-run --out-format='AREPA_CHANGE %i' $repo_path $remote_repo_path";
        my $changes = 0;

        open RSYNCOUTPUT, "$rsync_cmd |";
        while (<RSYNCOUTPUT>) {
            next unless /^AREPA_CHANGE/;
            if (/^AREPA_CHANGE [^.]/) {
                $changes = 1;
            }
        }
        close RSYNCOUTPUT;

        return (! $changes);
    }
    return 0;
}

1;

__END__

=head1 NAME

Arepa::Repository - Arepa repository access class

=head1 SYNOPSIS

 my $repo = Arepa::Repository->new('path/to/config.yml');
 my $value = $repo->get_config_key('repository:path');
 my @distros = $repo->get_distributions;
 my @archs = $repo->get_architectures;
 my $bool = $repo->insert_source_package($dsc_file, $distro);
 my $bool = $repo->insert_source_package($dsc_file, $distro,
                                         priority => 'optional',
                                         section  => 'perl');
 my $bool = $repo->insert_source_package($dsc_file, $distro,
                                         priority => 'optional',
                                         section  => 'perl',
                                         comments => 'Why this was approved',
                                         canonical_distro => 'lenny');
 my $bool = $repo->insert_binary_package($deb_file, $distro);
 my $text = $repo->last_cmd_output;

=head1 DESCRIPTION

This class represents a reprepro-managed APT repository. It allows you get
information about the repository and to insert new source and binary packages
in it.

It uses the Arepa configuration to get the repository path, and the own
repository reprepro configuration to figure out the distributions and
architectures inside it.

=head1 METHODS

=over 4

=item new($path)

Creates a new repository access object, using the configuration file in
C<$path>.

=item get_config_key($key)

Gets the configuration key C<$key> from the Arepa configuration.

=item get_distributions

Returns an array of hashrefs. Each hashref represents a distribution declared
in the repository C<conf/distributions> configuration file, and contains a
(always lowercase) key for every distribution attribute.

=item get_architectures

Returns a list of all the architectures mentioned in any of the repository
distributions.

=item insert_source_package($dsc_file, $distribution, %options)

Inserts the source package described by the given C<$dsc_file> in the
repository and the package database, for the given C<$distribution>. Priority
and section can be specified with the C<priority> and C<section> options in
C<%options>. Other possible options are C<comments> (comments about the source
package e.g. why it was added to the repo or its origin) and
C<canonical_distro> (the "canonical" distribution, that is the distribution in
your repository the source package should be added to, as opposed to the
distribution specified in the actual source package changes file).

=item insert_binary_package($deb_file, $distribution)

Inserts the given binary package C<$deb_file> in the repository, for the given
C<$distribution>.

=item last_cmd_output

Returns the text output of the last executed command. This can help debugging
problems.

=item get_package_list

Returns a data structure representing all the available packages in all the
known distributions. The data structure is a hash that looks like this:

 (foobar => { "lenny/main" => { "1.0-1" => ['source'] } },
  pkg2   => { "lenny/main" => { "1.0-1" => [qw(amd64 source)],
                                "1.0-2" => ['i386'], },
              "etch/contrib" =>
                              { "0.8-1" => [qw(i386 amd64 source) }
            },
  dhelp  => { "lenny/main" => { "0.6.15" => [qw(i386 source)] } },
 )

That is, the keys are the package names, and the values are another hash. This
hash has C<distribution/component> as keys, and hashes as values. These hashes
have available versions as keys, and a list of architectures as values.

=item get_source_package_information($package_name, $distro)

Returns a hash with the information for the source package with the given
C<$package_name> inside distribution C<$distro>. If there is no source package
by that name in that distribution, an empty hash will be returned.

Note that keys in the hash are lowercase.

=item get_binary_package_information($package_name, $distro, $arch)

Returns a hash with the information for the binary package with the given
C<$package_name> inside distribution C<$distro>/C<$arch>. If there is no binary
package by that name in that distribution, for that architecture, an empty hash
will be returned.

=item add_distribution(%properties)

Adds a new distribution to the repository, with whatever properties are
specified. The properties are specified in lowercase (see
C<get_distributions>) and C<codename> is mandatory. Also, you can't specify a
codename of an existing distribution, or a suite name that an existing
distribution already has. It returns 1 on success, or 0 on failure.

=item sign_distribution($dist_name)

Signs the C<Release> file for a single distribution (with codename
C<$dist_name>). It returns if GPG returned error status zero.

=item sync_remote

Syncs the local repository to the remote location, if available in the config.
Returns if the synchronisation worked (needs the C<rsync> command) or false if
there wasn't any remote repository location in the config. 

=item is_synced

Returns if the local repository is synced with the remote repository. It
returns false if there's no remote repository location in the config.

=back

=head1 SEE ALSO

C<Arepa::BuilderFarm>, C<Arepa::PackageDb>, C<Arepa::Config>.

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

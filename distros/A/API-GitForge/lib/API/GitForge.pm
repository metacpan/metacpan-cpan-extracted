package API::GitForge;
# ABSTRACT: generic interface to APIs of sites like GitHub, GitLab etc.
#
# Copyright (C) 2020  Sean Whitton <spwhitton@spwhitton.name>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
$API::GitForge::VERSION = '0.007';

use 5.028;
use strict;
use warnings;

use Carp;
use Exporter "import";
use File::Spec::Functions qw(catfile);
use Git::Wrapper;
use Cwd;
use API::GitForge::GitHub;
use API::GitForge::GitLab;

our @EXPORT_OK = qw(new_from_domain forge_access_token remote_forge_info);

our %known_forges = (
    "github.com"       => "API::GitForge::GitHub",
    "salsa.debian.org" => "API::GitForge::GitLab",
);


sub new_from_domain {
    my %opts = @_;
    croak "unknown domain" unless exists $known_forges{ $opts{domain} };
    $known_forges{ $opts{domain} }->new(%opts);
}


sub forge_access_token {
    my $domain = shift;
    my $root = $ENV{XDG_CONFIG_HOME} || catfile $ENV{HOME}, ".config";
    my $file = catfile $root, "gitforge", "access_tokens", $domain;
    -e $file and -r _ or croak "$file does not exist or is not readable";
    open my $fh, "<", $file or die "failed to open $file for reading: $!";
    chomp(my $key = <$fh>);
    $key;
}


sub remote_forge_info {
    my $remote = shift;
    my $git    = Git::Wrapper->new(getcwd);
    my ($uri) = $git->remote("get-url", $remote);
    $uri =~ m#^https?://([^:/@]+)/#
      or $uri =~ m#^(?:\w+\@)?([^:/@]+):#
      or croak "couldn't determine git forge info from $remote remote";
    ($1, $');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::GitForge - generic interface to APIs of sites like GitHub, GitLab etc.

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    # try to autodetect the forge type; works for GitHub and some others
    my $github = API::GitForge->new_from_domain(
        domain     => "github.com",
        access_key => "12345678"
    );

    # specify the forge type yourself by instantiating the right class
    my $salsa = API::GitForge::GitLab->new(
        domain     => "salsa.debian.org",
        access_key => "abcdef"
    );

    # generic user operations regardless of the forge type
    $github->clean_fork("spwhitton/git-remote-gcrypt");
    $salsa->clean_fork("Debian/devscripts");

=head1 DESCRIPTION

A I<git forge> is a site like GitHub, GitLab etc.  This module
provides access to some operations which one might wish to perform
against any git forge, wrapping the details of the APIs of particular
forges.  An example of such an operation is forking a repository into
the user's own namespace.

See L<API::GitForge::Role::GitForge> for details of all the currently
supported operations.  Patches adding other operations, and support
for other git forges, are welcome.

=head1 FUNCTIONS

=head2 new_from_domain domain => $domain, access_key => $key

Instantiate an object representing the GitForge at C<$domain> which
does L<API::GitForge::Role::GitForge>.  This function will only
succeed for known forges; see C<%API::GitForge::known_forges>.  The
C<access_key> argument is optional; if present, it should be an API
key for the forge.

    $API::GitForge::known_forges{"ourlab.com"} = "API::GitForge::GitLab";

    my $ourlab = API::GitForge::new_from_domain(
        domain     => "ourlab.com",
        access_key => API::GitForge::forge_access_token("ourlab.com")
    );

=head2 forge_access_token $domain

Return access token for forge at C<$domain>, assumed to be stored
under C<$ENV{XDG_CONFIG_HOME}/gitforge/access_tokens/$domain> where
the environment variable defaults to C<~/.config> if unset.

=head2 remote_forge_info $remote

Look at the URL for git remote C<$remote>, as returned by C<git remote
get-url>, assume that this remote is a git forge, and return the
domain name of that forge and the path to the repository.

    system qw(git remote add salsa https://salsa.debian.org/spwhitton/foo);
    my ($forge_domain, $forge_repo) = API::GitForge::remote_forge_info("salsa");

    say $forge_domain;          # outputs 'salsa.debian.org'
    say $forge_repo;            # outputs 'spwhitton/foo'

=head1 STATUS

Unstable.  Interface may change.

=head1 AUTHOR

Sean Whitton <spwhitton@spwhitton.name>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2020 by Sean Whitton <spwhitton@spwhitton.name>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

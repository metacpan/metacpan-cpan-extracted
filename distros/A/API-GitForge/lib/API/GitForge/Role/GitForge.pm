package API::GitForge::Role::GitForge;
# ABSTRACT: role implementing generic git forge operations
#
# Copyright (C) 2017, 2020  Sean Whitton <spwhitton@spwhitton.name>
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
$API::GitForge::Role::GitForge::VERSION = '0.003';

use 5.028;
use strict;
use warnings;

use Role::Tiny;

use Carp;
use File::Temp qw(tempdir);
use Git::Wrapper;
use File::Spec::Functions qw(catfile);


sub new {
    my ($class, %opts) = @_;
    croak "need domain!" unless exists $opts{domain};

    my %attrs = (_domain => $opts{domain});
    $attrs{_access_token} = $opts{access_token} if exists $opts{access_token};
    my $self = bless \%attrs => $class;

    $self->_make_api;

    return $self;
}


sub ensure_repo { shift->_create_repo(@_) }


sub clean_repo {
    my ($self, $repo) = @_;
    $self->_ensure_repo($repo);
    $self->_clean_config_repo($repo);
}


sub ensure_fork { shift->_ensure_fork(@_) }


sub clean_fork {
    my $self     = shift;
    my $fork_uri = $self->_ensure_fork($_[0]);

    my $temp = tempdir CLEANUP => 1;
    my $git = Git::Wrapper->new($temp);
    $git->init;
    my @fork_branches
      = map { m#refs/heads/#; $' } $git->ls_remote("--heads", $fork_uri);
    return $fork_uri if grep /\Agitforge\z/, @fork_branches;

    open my $fh, ">", catfile $temp, "README.md";
    say $fh "This repository exists only in order to submit pull request(s).";
    close $fh;
    $git->add("README.md");
    $git->commit({ message => "Temporary fork for pull request(s)" });

    $git->push($fork_uri, "master:gitforge");
    $self->_clean_config_fork($_[0]);

    # assume that if we had to create the gitforge branch, we just
    # created the fork, so can go ahead and nuke all branches there.
    if ($self->can("_ensure_fork_branch_unprotected")) {
        $self->_ensure_fork_branch_unprotected($_[0], $_) for @fork_branches;
    }
    # may fail if we couldn't unprotect; that's okay
    eval { $git->push($fork_uri, "--delete", @fork_branches) };

    return $fork_uri;
}


sub nuke_fork { shift->_nuke_fork(@_) }


sub clean_config_repo { shift->_clean_config_repo(@_) }


sub clean_config_fork { shift->_clean_config_fork(@_) }

requires
  qw<_make_api _ensure_repo _clean_config_repo _clean_config_fork
     _ensure_fork _nuke_fork>;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::GitForge::Role::GitForge - role implementing generic git forge operations

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Operations which one might wish to perform against any git forge.  See
L<API::GitForge>.

In this documentation, C<example.com> should be replaced with the
domain at which your git forge is hosted, e.g. C<salsa.debian.org>.

=head1 METHODS

=head2 new(domain => $domain, access_token => $token)

Instantiate an object representing the GitForge at C<$domain>.  The
C<access_key> argument is optional; if present, it should be an API
key for the forge.

=head2 ensure_repo($repo)

Create a new repo at C<https://example.com/$repo>.

=head2 clean_repo($repo)

Create a new repo at C<https://example.com/$repo> and turn off
optional forge features.

=head2 ensure_fork($upstream)

Ensure that the current user has a fork of the repo at
C<https://example.com/$upstream>, and return URI to that fork suitable
for adding as a git remote.

=head2 clean_fork($upstream)

Ensure that the current user has a fork of the repo at
C<https://example.com/$upstream>, config that fork to make it obvious
it's only there for submitting change proposals, and return URI to
fork suitable for adding as a git remote.

=head2 nuke_fork($upstream)

Delete the user's fork of the repo at
C<https://example.com/$upstream>.

=head2 clean_config_repo($repo)

Turn off optional forge features for repo at
C<https://example.com/$repo>.

=head2 clean_config_fork($upstream)

Configure user's fork of repo at C<https://example.com/$upstream> to
make it obvious that it's only there for submitting change proposals.

=head1 STATUS

Unstable.  Interface may change.

=head1 AUTHOR

Sean Whitton <spwhitton@spwhitton.name>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2020 by Sean Whitton <spwhitton@spwhitton.name>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

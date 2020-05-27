package API::GitForge::GitLab;
# ABSTRACT: common git forge operations using the GitLab API
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
$API::GitForge::GitLab::VERSION = '0.005';

use 5.028;
use strict;
use warnings;

use Role::Tiny::With;

use Carp;
use GitLab::API::v4;

with "API::GitForge::Role::GitForge";

sub _make_api {
    my $self = shift;
    my %opts = (url => "https://" . $self->{_domain} . "/api/v4");
    $opts{private_token} = $self->{_access_token}
      if exists $self->{_access_token};
    $self->{_api} = GitLab::API::v4->new(%opts);
}

sub _ensure_fork {
    my ($self, $upstream) = @_;
    my ($path, $repo)     = _extract_project_id($upstream);

    my $user = $self->{_api}->current_user->{username};
    my @user_repos;
    my $update_user_repos = sub {
        @user_repos
          = @{ $self->{_api}->projects({ search => "$user/$repo" }) };
    };
    my $repo_exists = sub {
        grep { $_->{path_with_namespace} eq "$user/$repo" } @user_repos;
    };
    &$update_user_repos;
    if (&$repo_exists) {
        $self->_assert_fork_has_parent($upstream);
    } else {
        $self->{_api}->fork_project("$path/$repo");
        until (&$repo_exists) {
            sleep 5;
            &$update_user_repos;
        }
    }
    return "https://" . $self->{_domain} . "/$user/$repo.git";
}

sub _assert_fork_has_parent {
    my ($self, $upstream) = @_;
    my ($path, $repo)     = _extract_project_id($upstream);
    my $user = $self->{_api}->current_user->{username};
    my $fork = $self->{_api}->project("$user/$repo");

    $fork->{forked_from_project}{path_with_namespace} eq $path . "/" . $repo
      or croak
      "$user/$repo does not have parent $upstream; don't know what to do";
}

sub _clean_config_repo {
    my ($self, $target) = @_;
    my ($ns,   $repo)   = _extract_project_id($target);

    $self->{_api}->edit_project(
        "$ns/$repo",
        {
            issues_access_level         => "disabled",
            merge_requests_access_level => "disabled",
        });
}

sub _clean_config_fork {
    my ($self, $upstream) = @_;
    my (undef, $repo)     = _extract_project_id($upstream);
    my $user = $self->{_api}->current_user->{username};

    $self->{_api}->edit_project(
        "$user/$repo",
        {
            default_branch      => "gitforge",
            description         => "Temporary fork for merge request(s)",
            issues_access_level => "disabled",
            # merge requests have to be enabled in the fork in order
            # to submit merge requests to the upstream repo from which
            # we forked, it seems
            merge_requests_access_level => "enabled",
        });
}

sub _ensure_repo {
    my ($self, $target) = @_;
    my ($ns,   $repo)   = _extract_project_id($target);
    return if $self->{_api}->project($target);
    my $namespace = $self->{_api}->namespace($ns)
      or croak "invalid project namespace $ns";
    $self->{_api}
      ->create_project({ name => $repo, namespace_id => $namespace->{id} });
}

sub _nuke_fork {
    my ($self, $upstream) = @_;
    $self->_assert_fork_has_parent($upstream);
    my (undef, $repo) = _extract_project_id($upstream);
    my $user = $self->{_api}->current_user->{username};
    $self->{_api}->delete_project("$user/$repo");
}

sub _ensure_fork_branch_unprotected {
    my ($self, $upstream, $branch) = @_;
    my (undef, $repo) = _extract_project_id($upstream);
    my $user = $self->{_api}->current_user->{username};
    return unless $self->{_api}->protected_branch("$user/$repo", $branch);
    $self->{_api}->unprotect_branch("$user/$repo", $branch);
}

sub _extract_project_id {
    my $project = shift;
    $project =~ s#(?:\.git)?/?$##;
    $project =~ m#/([^/]+)$#;
    ($`, $1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::GitForge::GitLab - common git forge operations using the GitLab API

=head1 VERSION

version 0.005

=head1 DESCRIPTION

See L<API::GitForge> and L<API::GitForge::Role::GitForge> for how to
use this class.

=head1 AUTHOR

Sean Whitton <spwhitton@spwhitton.name>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2020 by Sean Whitton <spwhitton@spwhitton.name>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

package API::GitForge::GitHub;
# ABSTRACT: common git forge operations using the GitHub API
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
$API::GitForge::GitHub::VERSION = '0.003';

use 5.028;
use strict;
use warnings;

use Role::Tiny::With;

use Carp;
use Net::GitHub;

with "API::GitForge::Role::GitForge";

sub _make_api {
    my $self = shift;
    my %opts;
    $opts{access_token} = $self->{_access_token}
      if exists $self->{_access_token};
    $self->{_api} = Net::GitHub->new(%opts);
}

sub _ensure_fork {
    my ($self, $upstream) = @_;
    my ($org,  $repo)     = _extract_repo($upstream);

    my $repos       = $self->{_api}->repos;
    my $user        = $self->{_api}->user->show->{login};
    my @user_repos  = $repos->list_user($user);
    my $repo_exists = sub {
        grep { $_->{name} eq $repo } @user_repos;
    };
    if (&$repo_exists) {
        $self->_assert_fork_has_parent($upstream);
    } else {
        $repos->create_fork($org, $repo);
        until (&$repo_exists) {
            sleep 5;
            @user_repos = $repos->list_user($user);
        }
    }
    return "https://github.com/$user/$repo";
}

sub _assert_fork_has_parent {
    my ($self, $upstream) = @_;
    my (undef, $repo)     = _extract_repo($upstream);
    my $user = $self->{_api}->user->show->{login};
    my $fork = $self->{_api}->repos->get($user, $repo);

    $fork->{parent}{full_name} eq $upstream
      or croak
      "$user/$repo does not have parent $upstream; don't know what to do";
}

sub _clean_config_repo {
    my ($self, $target) = @_;
    my ($org,  $repo)   = _extract_repo($target);
    my $repos = $self->{_api}->repos;
    $repos->set_default_user_repo($org, $repo);
    $repos->update({
        name          => "$repo",
        has_wiki      => 0,
        has_issues    => 0,
        has_downloads => 0,
        has_pages     => 0,
        has_projects  => 0,
    });
}

sub _clean_config_fork {
    my ($self, $upstream) = @_;
    my (undef, $repo)     = _extract_repo($upstream);
    my $user = $self->{_api}->user->show->{login};

    my $repos = $self->{_api}->repos;
    $repos->set_default_user_repo($user, $repo);
    $repos->update({
        name           => "$repo",
        homepage       => "",
        description    => "Temporary fork for pull request(s)",
        default_branch => "gitforge",
    });

    $self->_clean_config_repo("$user/$repo");
}

sub _ensure_repo {
    my ($self, $target) = @_;
    my ($org,  $repo)   = _extract_repo($target);
    my $repos       = $self->{_api}->repos;
    my $user        = $self->{_api}->user->show->{login};
    my %create_opts = (name => $repo);
    my $list_method;
    if ($org eq $user) {
        $list_method = "list_user";
    } else {
        $list_method = "list_org";
        $create_opts{org} = $org unless $org eq $user;
    }
    my @list_repos  = $repos->$list_method($org);
    my $repo_exists = sub {
        grep { $_->{name} eq $repo } @list_repos;
    };
    unless (&$repo_exists) {
        $repos->create(\%create_opts);
        until (&$repo_exists) {
            sleep 5;
            @list_repos = $repos->$list_method($org);
        }
    }
    return "https://github.com/$org/$repo";
}

sub _nuke_fork {
    my ($self, $upstream) = @_;
    $self->_assert_fork_has_parent($upstream);
    my (undef, $repo)     = _extract_repo($upstream);
    my $user = $self->{_api}->user->show->{login};
    $self->{_api}->repos->delete($user, $repo);
}

sub _extract_repo {
    $_[0] =~ m#^([^/]+)/(.+)(?:\.git)?$#;
    ($1, $2);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::GitForge::GitHub - common git forge operations using the GitHub API

=head1 VERSION

version 0.003

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

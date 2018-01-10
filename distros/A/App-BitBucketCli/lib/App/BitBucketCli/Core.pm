package App::BitBucketCli::Core;

# Created on: 2017-04-24 08:14:30
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use WWW::Mechanize;
use JSON::XS qw/decode_json encode_json/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use App::BitBucketCli::Project;
use App::BitBucketCli::Repository;
use App::BitBucketCli::Branch;
use App::BitBucketCli::PullRequest;
use YAML::Syck qw/Dump/;

our $VERSION = 0.003;

has url => (
    is      => 'rw',
    builder => '_url',
    lazy    => 1,
);
has host => (
    is      => 'rw',
    required => 1,
);
has [qw/user pass/] => (
    is  => 'rw',
);
has mech => (
    is      => 'rw',
    default => sub { WWW::Mechanize->new },
);
has opt => (
    is      => 'rw',
    default => sub {{}},
);

sub projects {
    my ($self) = @_;
    my @projects;
    my $last_page = 0;
    my $next_page_start = 0;
    my $limit = 30;

    while ( ! $last_page ) {
        my $json;
        eval {
            $json = $self->_get($self->url . "/projects?limit=$limit&start=$next_page_start");
            1;
        } || do {
            warn "Couldn't list repositories: $@\n";
            return [];
        };
        push @projects, @{ $json->{values} };
        $last_page = $json->{isLastPage};
        $next_page_start = $json->{nextPageStart};
    }

    return map {App::BitBucketCli::Project->new($_)} @projects;
}

sub repositories {
    my ($self, $project) = @_;
    my @repositories;
    my $last_page = 0;
    my $next_page_start = 0;
    my $limit = 30;

    while ( ! $last_page ) {
        my $json;
        eval {
            $json = $self->_get($self->url . "/projects/$project/repos?limit=$limit&start=$next_page_start");
            1;
        } || do {
            warn "Couldn't list repositories: $@\n";
            return [];
        };
        push @repositories, @{ $json->{values} };
        $last_page = $json->{isLastPage};
        $next_page_start = $json->{nextPageStart};
    }

    return map {App::BitBucketCli::Repository->new($_)} @repositories;
}

sub repository {
    my ($self, $project, $repository) = @_;

    my $json;
    eval {
        $json = $self->_get($self->url . "/projects/$project/repos/$repository");
        1;
    } || do {
        warn "Couldn't get repository information $@\n";
        return [];
    };

    return $json;
}

sub pull_requests {
    my ($self, $project, $repository, $state) = @_;
    my @pull_requests;
    my $last_page = 0;
    my $next_page_start = 0;
    my $limit = 30;

    while ( ! $last_page ) {
        my $json;
        eval {
            $json = $self->_get($self->url . "/projects/$project/repos/$repository/pull-requests?limit=$limit&start=$next_page_start");
            1;
        } || do {
            warn "Couldn't list pull_requests $@\n";
            return [];
        };
        push @pull_requests, @{ $json->{values} };
        $last_page = $json->{isLastPage};
        $next_page_start = $json->{nextPageStart};
    }

    return map {App::BitBucketCli::PullRequest->new($_)} @pull_requests;
}

sub branch {
    my ($self, @branches) = @_;

    my $branches = $self->get_branches($self->opt->{project}, $self->opt->{repository});

    for my $branch (sort keys %{ $branches }) {
        next if !grep {$branch eq $_} @branches;
        print "$branch\n";
    }

    return;
}

sub get_pull_requests {
    my ($self, $project, $repository, $state) = @_;
    my $json;
    my @prs;
    $state = $state ? "?state=$state" : '';

    my $next = $self->_get_all("/projects/$project/repos/$repository/pull-requests$state");

    while ( my $pr = $next->() ) {
        push @prs, App::BitBucketCli::PullRequest->new($pr);
    }

    return \@prs;
}

sub get_branches {
    my ($self, $project, $repository) = @_;
    my @branches;
    my $next = $self->_get_all("/projects/$project/repos/$repository/branches?orderBy=MODIFICATION&details=true");

    while ( my $branch = $next->() ) {
        $branch->{project}    = $project;
        $branch->{repository} = $repository;
        push @branches, App::BitBucketCli::Branch->new($branch);
    }

    return \@branches;
}

sub _get_all {
    my ($self, $url) = @_;
    my $last_page = 0;
    my $next_page_start = 0;
    my $limit = 30;

    my $json;

    return sub {
        if ( $json && @{ $json->{values} } ) {
            return shift @{ $json->{values} };
        }
        if ($last_page) {
            return;
        }

        my $page_url = $self->url . $url . ( $url =~ /[?]/ ? '&' : '?' ) . "limit=$limit&start=$next_page_start";
        $json = $self->_get($page_url);

        $last_page = $json->{isLastPage};
        $next_page_start = $json->{nextPageStart};

        return shift @{ $json->{values} || [] };
    };
}

sub _get {
    my ($self, $url) = @_;

    warn "$url\n" if $ENV{BB_SHOW_URLS};
    $self->mech->get($url);

    return decode_json($self->mech->content);
}

sub _url {
    my ($self) = @_;
    my $url = "https://";
    if ( $self->user ) {
        $url .= _url_encode($self->user);

        if ( $self->pass ) {
            $url .= ':' . _url_encode($self->pass);
        }
        $url .= '@';
    }
    $url .= $self->host . "/rest/api/1.0";

    return $url;
}

sub _url_encode {
    my $str = shift;
    $str =~ s/(\W)/sprintf('%%%x',ord($1))/eg;
    return $str;
}

1;

__END__

=head1 NAME

App::BitBucketCli::Core - Library for talking to BitBucket Server (or Stash)

=head1 VERSION

This documentation refers to App::BitBucketCli::Core version 0.003


=head1 SYNOPSIS

   use App::BitBucketCli::Core;

   # create a stash object
   my $stash = App::BitBucketCli::Core->new(
       url => 'http://stash.example.com/',
   );

   # Get a list of open pull requests for a repository
   my $prs = $stash->pull_requests($project, $repository);

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<branch ()>

=head2 C<get_branches ()>

=head2 C<get_pull_requests ()>

=head2 C<projects ()>

=head2 C<pull_requests ( $project, $repository, $state )>

Gets all of the pull requests in C<$state>.

=head2 C<repositories ( $project )>

Gets details of all repositories of $project

=head2 C<repository ( $project, $repository )>

Gets details of a repository

=head1 ATTRIBUTES

=head2 url

=head2 host

=head2 user

=head2 pass

=head2 mech

=head2 opt

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

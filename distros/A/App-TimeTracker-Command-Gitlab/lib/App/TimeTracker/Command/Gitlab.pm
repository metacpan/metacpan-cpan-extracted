package App::TimeTracker::Command::Gitlab;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker Gitlab plugin
use App::TimeTracker::Utils qw(error_message warning_message);

our $VERSION = "1.002";

use Moose::Role;
use HTTP::Tiny;
use JSON::XS qw(encode_json decode_json);

has 'issue' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'gitlab issue',
    predicate     => 'has_issue'
);

has 'gitlab_client' => (
    is         => 'rw',
    isa        => 'Maybe[HTTP::Tiny]',
    lazy_build => 1,
    traits     => ['NoGetopt'],
);

sub _build_gitlab_client {
    my $self   = shift;
    my $config = $self->config->{gitlab};

    unless ( $config->{url} && $config->{token} ) {
        error_message(
            "Please configure Gitlab in your TimeTracker config (needs url & token)"
        );
        return;
    }

    return HTTP::Tiny->new(default_headers=>{
        'PRIVATE-TOKEN'=> $self->config->{gitlab}{token},
    });
}

has 'project_id' => (
    is=>'ro',
    isa=>'Str',
    documentation=>'The ID or namespace/name of this project',
    lazy_build=>1,
);

sub _build_project_id {
    my $self = shift;
    return $self->config->{gitlab}{project_id} if $self->config->{gitlab}{project_id};
    my $name = $self->config->{project};
    my $namespace = $self->config->{gitlab}{namespace} || '' ;
    if ($name && $namespace) {
        return join('%2F',$namespace, $name);
    }
    error_message("Please set either project_id, or project and namespace");
    return
}

before [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;
    return unless $self->has_issue;

    my $issuename = 'issue#' . $self->issue;
    $self->insert_tag($issuename);

    my $issues = $self->_call('GET','projects/'.$self->project_id.'/issues?iid='.$self->issue);
    my $issue = $issues->[0];
    unless ($issue) {
        error_message("Cannot find issue %s in %s",$self->issue,$self->project_id);
        return;
    }
    my $name = $issue->{title};

    if ( defined $self->description ) {
        $self->description( $self->description . ' ' . $name );
    }
    else {
        $self->description($name);
    }

    if ( $self->meta->does_role('App::TimeTracker::Command::Git') ) {
        my $branch = $self->issue;
        if ($name) {
            $branch = $self->safe_branch_name($self->issue.' '.$name);
        }
        $branch=~s/_/-/g;
        $self->branch( lc($branch) ) unless $self->branch;
    }

    # TODO set assignee

};

#after [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
#    my $self = shift;
#    TODO: do we want to do something after stop?
#};

sub _call {
    my ($self,$method,  $endpoint, $args) = @_;

    my $url = $self->config->{gitlab}{url}.'/api/v3/'.$endpoint;
    my $res = $self->gitlab_client->request($method,$url);

    if ($res->{success}) {
        my $data = decode_json($res->{content});
        return $data;
    }
    error_message(join(" ",$res->{status},$res->{reason}));
}

sub App::TimeTracker::Data::Task::gitlab_issue {
    my $self = shift;
    foreach my $tag ( @{ $self->tags } ) {
        next unless $tag =~ /^issue#(\d+)/;
        return $1;
    }
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::Gitlab - App::TimeTracker Gitlab plugin

=head1 VERSION

version 1.002

=head1 DESCRIPTION

Connect tracker with L<Gitlab|https://about.gitlab.com/>.

Using the Gitlab plugin, tracker can fetch the name of an issue and use
it as the task's description; generate a nicely named C<git> branch
(if you're also using the C<Git> plugin).

Planned but not implemented: Adding yourself as the assignee.

=head1 CONFIGURATION

=head2 plugins

Add C<Gitlab> to the list of plugins.

=head2 gitlab

add a hash named C<gitlab>, containing the following keys:

=head3 url [REQUIRED]

The base URL of your gitlab instance, eg C<https://gitlab.example.com>

=head3 token [REQUIRED]

Your personal access token. Get it from your gitlab profile page. For
now you probably want to use a token with unlimited expiry time. We
might implement a way to fetch a shortlived token (like in the Trello
plugin), but gitlab does not support installed-apps OAuth2.

=head3 namespace [REQUIRED]

The C<namespace> of the current project, eg C<validad> if this is your repo: C<https://gitlab.example.com/validad/App-TimeTracker-Gitlab>

=head1 NEW COMMANDS

No new commands

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue

=head3 --issue

    ~/perl/Your-Project$ tracker start --issue 42

If C<--issue> is set and we can find an issue with this id in your current repo

=over

=item * set or append the issue name in the task description ("Rev up FluxCompensator!!")

=item * add the issue id to the tasks tags ("issue#42")

=item * if C<Git> is also used, determine a save branch name from the issue name, and change into this branch ("42-rev-up-fluxcompensator")

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

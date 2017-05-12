package App::Gitc::Its::Github;
use strict;
use warnings;

# ABSTRACT: Support for Github Issue Tracking
our $VERSION = '0.60'; # VERSION


use YAML::Syck;
use Pithub::Issues;

use App::Gitc::Util qw(
    get_user_name
    get_user_email
    git
    project_config
    project_name
    command_name
    current_branch
);
use List::MoreUtils qw(any);

sub label_service { return 'Github'; }
sub label_issue { return 'Issue'; }

sub get_issue {
    my ($self, $changeset, %params) = @_;

    my $number = $self->issue_number($changeset) or return undef;

    our %github_issue;
    return $github_issue{$number} 
        if exists $github_issue{$number} and not $params{reload};

    my $issue = eval {
        my $github = $self->get_github_object or return;
        my $issue = $self->_get_issue($number);
        die "Issue $number didn't return an object" unless $issue;
        return $github_issue{$number} = $issue;
    };

    warn "Error accessing Github: $@" if $@;
    return $issue;
}

sub get_github_object {
    my ($self) = @_;

    our $github;
    if (!$github) {
        my %opts = $self->get_github_opts;
        $github = Pithub::Issues->new(%opts);
    }

    return $github;
}

our $github_conf;

sub get_github_opts {
    if (not $github_conf and -e "$ENV{HOME}/.gitc/github.conf") {
        $github_conf = LoadFile("$ENV{HOME}/.gitc/github.conf");
    }
    else {
        $github_conf ||= {}; 
    }
    
    my $project = project_name(); 

    my ($owner, $repo) = @{$github_conf->{$project}}{qw/Owner Repo/};
    unless ($owner and $repo) { # default to using the repo they cloned
        my $url = git "config --get remote.origin.url";
        my ($o, $r) = $url =~ m|/([^/]+?)/([^/]+?)(?:\.git)?$|;
        $owner ||= $o;
        $repo  ||= $r;
    }

    return (
        user => $owner,
        repo => $repo, 
        prepare_request => sub {
            return shift->authorization_basic(@{$github_conf}{qw(Username Password)});
        },
    );
}

sub _get_issue {
    my ($self, $number) = @_;

    our $github;
    $github ||= $self->get_github_object;

    my $r = $github->get(issue_id => $number);
    die "Issue $number didn't return an object" unless $r->response->code == 200;
    return $r->content;
}

sub issue_number {
    my ($self, $changeset_or_number) = @_;

    $changeset_or_number =~ s/.*?(\d+)[a-z]?$/$1/;
    
    return $changeset_or_number;
}

sub issue_summary {
    my ($self, $issue) = @_;
    return unless $issue;

    return $issue->{title};
}

sub last_status {
    my ($self, $branch) = @_;
    return unless $branch;

    my $meta_data = App::Gitc::Util::view_blob("meta/$branch") or die "No meta data found for $branch";
    return unless @$meta_data > 1;

    my $to;
    for (my $i = @$meta_data - 2; $i >= 0; $i--) {
        my $command = $meta_data->[$i]{action};
        my $status;
        if (my $target = $meta_data->[$i]{target}) {
            $status = project_config()->{github_statuses}{$command}{$target} or next;
        }
        else {
            $status = project_config()->{github_statuses}{$command} or next;
        }
        $to = $status->{to} and last;
    }

    return $to;
}

sub transition_state {
    my ($self, $args) = @_;
    $args ||= {};
    $args->{with_time} = 1 unless exists $args->{with_time};
    return "Skipping Github changes, as requested by GITC_NO_GITHUB\n"
        if $ENV{GITC_NO_GITHUB};

    my $label = $self->label_issue;
    # validate the arguments
    my ($command, $message, $reviewer, $issue) = @{$args}{qw/command message reviewer issue/};
    die "No message" unless $message;
    $issue = $self->get_issue(current_branch(), reload => 1) unless defined $issue;
    return "NOT CHANGING Github $label: changeset not in Github?\n"
        if not $issue;
    my $state = $self->_states( $command, $args->{target} );
    my $to = $state->{to};
    my $from = $self->last_status($args->{changeset});

    $message = get_user_name()   # user's name
        . ": $message\n";

    my ( $rc );
    eval {
        my $github = $self->get_github_object or return;
        my $r = $github->comments->create(issue_id => $issue->{number}, data => {body => $message});
        die "Could not comment on issue $issue->{number}" unless $r->response->code == 201;
        $r = $github->labels->remove(issue_id => $issue->{number}, label => $from) if $from; 
        $r = $github->labels->add(issue_id => $issue->{number}, data => [$to]);
        die "Could not update issue $issue->{number}" unless $r->response->code == 200;
        $rc = ($r->content->[0]{name} eq $to); 
    };
    die $@ if $@;

    if ($rc) {
        return "Changed Github $label to '$to'\n";
    }
    else {
        return "NOT CHANGING GITHUB $label: currently '%s'\n",
            $self->issue_state($issue);
    }
}

sub issue_state {
    my ($self, $issue) = @_;
    return unless $issue;

    return $issue->{labels}[0]{name};
}

sub issue_changeset_uri {
    my ($self, $issue) = @_;

    return $issue->{html_url};
}

sub issue_project {
    my ($self, $issue) = @_;
    return unless $issue;

    my ($project) = $issue->{url} =~ m|([^/]+)/issues/\d+$|;
}

sub issue_promotion_notes {
return;
}

sub issue_scheduled_release {
return;
}

1;

__END__

=pod

=head1 NAME

App::Gitc::Its::Github - Support for Github Issue Tracking

=head1 VERSION

version 0.60

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Grant Street Group.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

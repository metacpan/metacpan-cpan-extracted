package App::JC::Client::listIssues;
#ABSTRACT: class implementing the add issue command of the jira client
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::JC::Client);

use Term::ANSIColor;
use Try::Tiny;
use JIRA::Client::Automated;

# the version of the module
our $VERSION = '0.001';

use String::Formatter named_stringf => {
  codes => {
    s => sub { $_ },     # string itself
  },
};

command_short_description 'create an issue within a project';
command_usage 'jc.pl add_issue <project> <type> <summary> <description>';


option 'project' => (
      is                => 'ro',
      isa               => 'Str',
      required          => 1,
      documentation     => q[The Project in which to create the issue],
      cmd_aliases       => [qw(p)], # Alternative option name
  );

  option 'tasktype' => (
        is                => 'ro',
        isa               => 'Str',
        required          => 0,
        default           => "all",
        documentation     => q[what kind of issue to add],
        cmd_aliases       => [qw(t)], # Alternative option name
    );

  option 'start' => (
        is                => 'ro',
        isa               => 'Int',
        required          => 0,
        default           => 1,
        documentation     => q[at which search result to start],
        cmd_aliases       => [qw(s)], # Alternative option name
    );

  option 'max' => (
        is                => 'ro',
        isa               => 'Int',
        required          => 0,
        default           => 100,
        documentation     => q[maximum number of results to show],
        cmd_aliases       => [qw(m)], # Alternative option name
    );

  option 'format' => (
        is                => 'ro',
        isa               => 'Str',
        required          => 0,
        default           => '%10{key}s %{summary}s',
        documentation     => q[in which format to show the output],
  );


sub run
{
  my $self        = shift;

  my $jira = JIRA::Client::Automated->new($self->url, $self->user, $self->pass);

  my $jql = "project = " . $self->project;

  my $search_results = $jira->search_issues($jql, $self->start, $self->max); # query should be a single string of JQL

  for my $issue (@{$search_results->{issues}})
  {
    my $str=named_stringf($self->format(), {
                      key             => $issue->{key},
                      summary         => $issue->{fields}->{summary},
                      project_key     => $issue->{fields}->{project}->{key},
                      project_name    => $issue->{fields}->{project}->{name},
                      labels          => $issue->{fields}->{labels},
                      creator_user    => $issue->{fields}->{creator}->{name},
                      creator_key     => $issue->{fields}->{creator}->{key},
                      creator_name    => $issue->{fields}->{creator}->{displayName},
                      priority        => $issue->{fields}->{priority}->{name},
                      type            => $issue->{fields}->{issuetype}->{name},
                      description     => $issue->{fields}->{description},

    });

    printf($str . "\n");
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JC::Client::listIssues - class implementing the add issue command of the jira client

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This command lists all the issues from a given project.

=head2 special Parameter

=head3 --format

The default format to print one issue ist to print the Project key,
following the project summary.

The Format parameter supports changing the default format and print
other issue information in a totally different format.

JC uses the String::Formatter module for parsing the format string.

The following issue information is supported at the moment:

=over

=item key - the key of the issue

=item summary - the summary of the issue

=item description - the full description of the issue

=item project_key - the key of the project owning the issue

=item project_name - the name of the project owning the issue

=item labels - the labels of an issue

=item creator_user - the username of the creator of an issue

=item creator_key - the key of the creator of an issue

=item creator_name - the display name of the creator of an issue

=item priority - the priority of an issue

=item type - the type of an issue

=back

=head1 METHODS

=head2 run

  execute the actual command, in  this case request the list of issues from
  the JIRA server.

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

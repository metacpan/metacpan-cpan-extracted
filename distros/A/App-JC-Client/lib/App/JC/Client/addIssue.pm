package App::JC::Client::addIssue;
#ABSTRACT: class implementing the add issue command of the jira client
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::JC::Client);

use Term::ANSIColor;
use Try::Tiny;
use JIRA::Client::Automated;


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
        default           => "Task",
        documentation     => q[what kind of issue to add],
        cmd_aliases       => [qw(t)], # Alternative option name
    );


    option 'summary' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 1,
          documentation     => q[The summary of the issue],
          cmd_aliases       => [qw(s)], # Alternative option name
      );

    option 'description' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 0,
          default           => "",
          documentation     => q[a description of the issue],
          cmd_aliases       => [qw(d)], # Alternative option name
      );

sub run
{
  my $self        = shift;

  my $jira = JIRA::Client::Automated->new($self->url, $self->user, $self->pass);
  my $issue = $jira->create_issue($self->project, $self->tasktype, $self->summary, $self->description);

  if (!defined($issue))
  {
    die("ERROR creating issue\n");
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JC::Client::addIssue - class implementing the add issue command of the jira client

=head1 VERSION

version 0.001

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

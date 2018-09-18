package App::Git::IssueManager::SyncJira;
#ABSTRACT: class implementing the sync_jira issue command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;
use JIRA::Client::Automated;
use Data::Dumper;

command_short_description 'sync the issues of a JIRA project with git-issue';
command_usage 'git issue sync_jira -p AFSM --url https://jiraserver --user jirauser --pass jirapass -t Aufgabe:feature';



option 'dryrun' => (
     is            => 'ro',
     isa           => 'Bool',
     documentation     => q[do not save issue to git-issue but generate issues to check for compatibility],
 );

 option 'project' => (
      is                => 'ro',
      isa               => 'Str',
      required          => 1,
      documentation     => q[The Project in which to create the issue],
      cmd_aliases       => [qw(p)], # Alternative option name
  );

  option 'url' => (
                    is => 'rw',
                    isa=>"Str",
                    required=>1,
                    documentation=>"JIRA URL"
                  );

  option 'user' => (
                    is => 'rw',
                    isa=>"Str",
                    required=>1,
                    documentation=>"JIRA User"
                  );

  option 'pass' => (
                    is => 'rw',
                    isa=>"Str",
                    required=>1,
                    documentation=>"JIRA Password"
                  );


  option 'type_mapping' => (
      is                => 'ro',
      isa               => 'ArrayRef[Str]',
      required          => 0,
      documentation     => q[map jira issue types to git-issue issue types. Format -t Aufgabe:task],
      cmd_aliases       => [qw(t)],
      default           => sub{return [];}
  );

  option 'stati_mapping' => (
      is                => 'ro',
      isa               => 'ArrayRef[Str]',
      required          => 0,
      documentation     => q[map jira issue stati to git-issue stati. Format -s Fertig:closed],
      cmd_aliases       => [qw(s)],
      default           => sub{return [];}
  );


sub run
{
  my $self        = shift;
  my $manager     = Git::IssueManager->new(repository=>Git::LowLevel->new(git_dir=> "."));
  my $typemap     = {};
  my $statimap    = {};

  if (!$manager->ready)
  {
    print("IssueManager not initialized yet. Please call \"init\" command to do so.");
    exit(-1);
  }

  for my $t (@{$self->type_mapping})
  {
    if ($t =~ /^(\S+):(\S+)$/ )
    {
      $typemap->{$1}=$2;
    }
  }

  for my $s (@{$self->stati_mapping})
  {
    if ($s =~ /^(\S+):(\S+)$/ )
    {
      $statimap->{$1}=$2;
    }
  }

  my $jira = JIRA::Client::Automated->new($self->url, $self->user, $self->pass);
  my $jql = "project = " . $self->project;
  my $search_results = $jira->search_issues($jql,0, 1000000000);

  for my $issue (@{$search_results->{issues}})
  {
    my $type        = $typemap->{$issue->{fields}->{issuetype}->{name}} || $issue->{fields}->{issuetype}->{name};
    my $priority    = $issue->{fields}->{priority}->{name};
    my $severity    = "low";
    my $status      =  $statimap->{$issue->{fields}->{status}->{name}} || $issue->{fields}->{status}->{name};
    my $description = $issue->{fields}->{description} || "no description";
    my $author      = $issue->{fields}->{creator}->{displayName} || "";
    my $author_email= $issue->{fields}->{creator}->{emailAddress} || "";
    my $worker      = $issue->{fields}->{assignee}->{displayName} || "";
    my $worker_email= $issue->{fields}->{assignee}->{emailAddress} || "";
    my $subject     = substr($issue->{fields}->{summary},0,50);

    my $gitissue       = Git::IssueManager::Issue->new(subject => $subject);
    $gitissue->description($description);
    $gitissue->priority($priority);
    $gitissue->severity($severity);
    $gitissue->type($type);
    $gitissue->author($author);
    $gitissue->author_email($author_email);
    $gitissue->worker($worker);
    $gitissue->worker_email($worker_email);
    $gitissue->status($status);

    $manager->add($gitissue) unless $self->dryrun();
  }

}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::SyncJira - class implementing the sync_jira issue command of the GIT IssueManager

=head1 VERSION

version 0.1

=head1 DESCRIPTION

  Through the sync_jira command issues can be synced from the JIRA Project Management Software to git-issue.

  B<At the moment only importing issues from JIRA is supported!>

  Mapping Issues from Jira to git-issue is not so easy because types, priorities, and stati do not much.
  To overcome these problems the command provides type, priority and stati mapping options.
  This command provides no complete support for all Jira issue attributes just enough to support my requiremens.

  If you have the need for a more thourough implementation just message me byterazor@federationhq.de.

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/App::Git::IssueManager::SyncJira/>.

=head1 BUGS

Please report any bugs or feature requests by email to
L<app-git-issuemanager-syncjira-bugtracker@federationhq.de|mailto:app-git-issuemanager-syncjira-bugtracker@federationhq.de>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

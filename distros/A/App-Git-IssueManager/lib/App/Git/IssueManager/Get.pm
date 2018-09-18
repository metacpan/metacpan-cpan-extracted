package App::Git::IssueManager::Get;
#ABSTRACT: class implementing the get issue command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;

use Term::ANSIColor;
use Try::Tiny;


command_short_description 'get an issue of a repository identified by the given id';
command_usage 'git issue get -i TST-a34df432';

option 'id' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 1,
          documentation     => q[the id of the issue],
          cmd_aliases       => [qw(i)]
);

sub run
{
  my $self        = shift;
  my $manager     = Git::IssueManager->new(repository=>Git::LowLevel->new(git_dir=> "."));
  if (!$manager->ready)
  {
    print("IssueManager not initialized yet. Please call \"init\" command to do so.");
    exit(-1);
  }

  my $issue=$manager->get($self->id);

  printf("%20s: %30s\n", "ID", $issue->id);
  printf("%20s: %30s\n", "Subject", $issue->subject);
  printf("%20s: %30s\n", "Type", $issue->type);
  printf("%20s: %30s\n", "Priority", $issue->priority);
  printf("%20s: %30s\n", "Severity", $issue->severity);
  printf("%20s: %30s\n", "Creation Date", $issue->creation_date()->ymd()." ".$issue->creation_date->hms());
  printf("%20s: %30s\n", "Author", $issue->author);
  printf("%20s: %30s\n", "Author Email", $issue->author_email);
  printf("%20s: %30s\n", "Status", $issue->status);
  if ($issue->status eq "closed")
  {
  printf("%20s: %30s\n", "Closed Date", $issue->closed_date()->ymd()." ".$issue->closed_date->hms());
  }
  printf("%20s: %30s\n", "Substatus", $issue->substatus);
  printf("%20s: %30s\n", "Comment", $issue->comment);
  printf("%20s: %30s\n", "Tags", join(",", @{$issue->tags}));
  printf("%20s: %30s\n", "Assignee", $issue->worker);
  printf("%20s: %30s\n", "Assignee Email", $issue->worker_email);
  printf("%20s: %30s\n", "Last Change Date", $issue->last_change_date()->ymd()." ".$issue->last_change_date->hms());
  printf("%20s: \n %s\n", "Description",$issue->description);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::Get - class implementing the get issue command of the GIT IssueManager

=head1 VERSION

version 0.1

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/App::Git::IssueManager/>.

=head1 BUGS

Please report any bugs or feature requests by email to
L<byterazor@federationhq.de|mailto:byterazor@federationhq.de>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

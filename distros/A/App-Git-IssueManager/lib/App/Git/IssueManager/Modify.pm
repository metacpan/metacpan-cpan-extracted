package App::Git::IssueManager::Modify;
#ABSTRACT: class implementing the modify issue command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;
use App::Git::IssueManager::Config;
use File::Temp qw/ tempfile/;
use File::Slurp;
use Term::ANSIColor;
use Try::Tiny;


command_short_description 'modify an issue within a project';
command_usage 'git issue add -s Humbug';

option 'subject' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 0,
          documentation     => q[the subject/title of the issue],
          cmd_aliases       => [qw(s)]
);

option 'priority' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 0,
          documentation     => q[the priority of the issue (low, medium, high, urgent)],
          cmd_aliases       => [qw(p)],
          default           => ""
);

option 'severity' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 0,
          documentation     => q[the severity of the issue (low, medium, high, critical)],
          cmd_aliases       => [qw(e)],
          default           => ""
);

option 'type' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 0,
          documentation     => q[the type of the issue (bug, security-bug, improvement, feature, task)],
          cmd_aliases       => [qw(t)],
          default           => ""
);

option 'description' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 0,
          documentation     => q[the description of the issue, only plain text or markdown. If not given an editor is started.],
          cmd_aliases       => [qw(d)],
          default           => ""
);

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

  my $modifications={};

  if ($self->type)
  {
    $modifications->{type}=$self->type;
  }

  if ($self->subject)
  {
    $modifications->{subject}=$self->subject;
  }

  if ($self->priority)
  {
    $modifications->{priority}=$self->priority;
  }

  if ($self->severity)
  {
    $modifications->{severity}=$self->severity;
  }

  if ($self->description)
  {
    $modifications->{description}=$self->description;
  }

  $manager->modify($self->id,$modifications);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::Modify - class implementing the modify issue command of the GIT IssueManager

=head1 VERSION

version 0.2

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

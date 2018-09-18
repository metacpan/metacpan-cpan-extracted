package App::Git::IssueManager::Assign;
#ABSTRACT: class implementing the assign issue command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;

use Term::ANSIColor;
use Try::Tiny;


command_short_description 'assign an issue from a repository identified by the given id to a user';
command_usage 'git issue assign -i TST-a34df432 -w "Dominik Meyer <dmeyer@federationhq.de>"';

option 'id' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 1,
          documentation     => q[the id of the issue],
          cmd_aliases       => [qw(i)]
);

option 'worker' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 1,
          documentation     => q[the user to assign the issue to],
          cmd_aliases       => [qw(w)]
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

  $self->worker() =~ /^(.*)<(.*)>$/;
  my $issue=$manager->assign($self->id, $1, $2);
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::Assign - class implementing the assign issue command of the GIT IssueManager

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

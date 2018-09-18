package App::Git::IssueManager::Init;
#ABSTRACT: class implementing the init command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;

use Term::ANSIColor;
use Try::Tiny;


command_short_description 'initialize IssueManager in the current git repository';
command_usage 'git issue init -t TST';

option 'tag' => (
          is                => 'ro',
          isa               => 'Str',
          required          => 1,
          documentation     => q[the tag to prepend in front of issue ids (eg. TST-ab5436fe, TST is the tag)],
          cmd_aliases       => [qw(t)]
);


sub run
{
  my $self        = shift;

  my $manager     = Git::IssueManager->new(repository=>Git::LowLevel->new(git_dir=> "."));
  if (!$manager->ready)
  {
    $manager->init($self->tag);
  }
  else
  {
    die("IssueManager already initialized");
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::Init - class implementing the init command of the GIT IssueManager

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

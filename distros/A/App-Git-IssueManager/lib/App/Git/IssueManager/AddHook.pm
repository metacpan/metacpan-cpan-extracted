package App::Git::IssueManager::AddHook;
#ABSTRACT: class implementing the Add-Hook command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;

use Term::ANSIColor;
use Try::Tiny;


command_short_description 'add the post-commit hook for managing git issues to the repository';
command_usage 'git issue add-hook';

sub run
{
  my $self        = shift;

  die("No .git directory found\n") unless -d ".git";
  die("A post-commit hook is already installed. Please add hook manually\n") unless ! -e ".git/hooks/post-commit";

  open my $hook,">",".git/hooks/post-commit";
  print $hook "#!/bin/sh\n";
  print $hook "git-issue-commit-hook\n";
  close $hook;

  system("chmod a+x .git/hooks/post-commit");


}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::AddHook - class implementing the Add-Hook command of the GIT IssueManager

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

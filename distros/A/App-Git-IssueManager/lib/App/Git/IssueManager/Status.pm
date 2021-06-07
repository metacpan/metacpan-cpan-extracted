package App::Git::IssueManager::Status;
#ABSTRACT: class implementing the status issue command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;
use Text::ANSITable;
use Term::ANSIColor;
use Try::Tiny;
use Data::Dumper;

command_short_description 'get the status of issues repository';
command_usage 'git issue status';

sub run
{
  my $self        = shift;

  my $manager     = Git::IssueManager->new(repository=>Git::LowLevel->new(git_dir=> "."));
  if (!$manager->ready)
  {
    print("IssueManager not initialized yet. Please call \"init\" command to do so.");
    exit(-1);
  }
  binmode(STDOUT, ":utf8");
  my $stats=$manager->stats();
  my $tag = $manager->tag();

  my $t = Text::ANSITable->new;
  $t->use_utf8(1);
  $t->use_color(1);
  $t->use_box_chars(1);
  $t->border_style('Default::single_boxchar');
  $t->columns(["Name","Value"]);
  $t->add_row(["Open Issues",$stats->{open}]);
  $t->add_row(["Assigned Issues",$stats->{assigned}]);
  $t->add_row(["Inprogress Issues",$stats->{inprogess}]);
  $t->add_row(["Closed Issues",$stats->{closed}]);

  print $t->draw;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::Status - class implementing the status issue command of the GIT IssueManager

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

package App::Git::IssueManager::List;
#ABSTRACT: class implementing the add issue command of the GIT IssueManager
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::Git::IssueManager);
use Git::LowLevel;
use Git::IssueManager;
use Git::IssueManager::Issue;
use Text::ANSITable 0.602;
use Term::ANSIColor;
use Try::Tiny;
use Data::Dumper;

command_short_description 'list issues of a repository';
command_usage 'git issue list';

option 'show_status' => (
    is                => 'rw',
    isa               => 'ArrayRef[Str]',
    required          => 0,
    documentation     => q[select which issues with which stati should be displayd (open, assigned, inprogress, closed, all)],
    cmd_aliases       => [qw(s)],
    default           => sub {return ["open"];}
);

sub run
{
  my $self        = shift;
  my @stati=@{$self->show_status};

  #remove all numbers from array
  my @help;
  for my $s (@stati)
  {
    push(@help,$s) unless $s =~/^\d+$/;
  }
  @stati=@help;
  $self->show_status(\@help);

  my @all_stati=("open","closed","assigned","inprogress","all");

  # check if a wrong status is requested
  for my $s (@{$self->show_status})
  {
    if(!grep( /^$s$/, @all_stati ))
    {
      die("ERROR: unkown status  \"" . $s . "\"\n");
    }
  }

  # check if all issues are requested

  if (grep( /^all$/, @stati ) )
  {
    $self->show_status(['open','closed','inprogress','assigned']);
  }

  my $manager     = Git::IssueManager->new(repository=>Git::LowLevel->new(git_dir=> "."));
  if (!$manager->ready)
  {
    print("IssueManager not initialized yet. Please call \"init\" command to do so.");
    exit(-1);
  }
  binmode(STDOUT, ":utf8");
  my @issues=$manager->list();

  my $t = Text::ANSITable->new;
  $t->use_utf8(1);
  $t->use_color(1);
  $t->border_style('UTF8::SingleLine');
  $t->columns(["ID", "Subject", "Type", "Priority", "Severity", "Status", "Author", "Worker"]);
  @stati=@{$self->show_status};
  for my $i (@issues)
  {
    my $status=$i->status;
    if ( grep( /^$status$/, @stati ) ) {
      if ( $i->priority eq "high" || $i->priority eq "urgent" || ($i->severity eq "high") || ($i->severity eq "critical") )
      {
        $t->add_row([$i->id,$i->subject,$i->type, $i->priority,$i->severity,$i->status,$i->author,$i->worker],{bgcolor=>'c60505'});
      }
      else
      {
        $t->add_row([$i->id,$i->subject,$i->type, $i->priority,$i->severity,$i->status,$i->author,$i->worker]);
      }
    }
  }
  print $t->draw;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Git::IssueManager::List - class implementing the add issue command of the GIT IssueManager

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

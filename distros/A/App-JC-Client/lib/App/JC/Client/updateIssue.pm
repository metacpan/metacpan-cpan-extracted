package App::JC::Client::updateIssue;
#ABSTRACT: class implementing starting of an issue
use strict;
use warnings;
use MooseX::App::Command;
extends qw(App::JC::Client);

use Term::ANSIColor;
use Try::Tiny;
use JIRA::Client::Automated;

# the version of the module
our $VERSION = '0.001';

command_short_description 'update an issue';
command_usage 'jc.pl update -i <issuekey> <options>';


option 'issuekey' => (
      is                => 'ro',
      isa               => 'Str',
      required          => 1,
      documentation     => q[The key of the issue to update],
      cmd_aliases       => [qw(i)], # Alternative option name
  );

option 'estimatedTime' => (
      is                => 'ro',
      isa               => 'Str',
      required          => 0,
      documentation     => q[The estimatedTime of finish for the Issue (10m, 2d, 1w, ...)],
      cmd_aliases       => [qw(e)], # Alternative option name
  );


sub run
{
  my $self        = shift;

  my $jira = JIRA::Client::Automated->new($self->url, $self->user, $self->pass);

  my $issue = $jira->get_issue($self->issuekey);
  if (!defined($issue))
  {
    die("ERROR: issue does not exist\n");
  }

  my $update;

  if ($self->estimatedTime=~/\S+/)
  {
      $update->{timetracking}->{originalEstimate}=$self->estimatedTime;
  }

  $issue=$jira->update_issue($self->issuekey, $update);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JC::Client::updateIssue - class implementing starting of an issue

=head1 VERSION

version 0.001

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

package App::JC::Client::start;
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

command_short_description 'start an issue';
command_usage 'jc.pl start <issuekey>';


option 'issuekey' => (
      is                => 'ro',
      isa               => 'Str',
      required          => 1,
      documentation     => q[The key of the issue to start],
      cmd_aliases       => [qw(i)], # Alternative option name
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
  $jira->assign_issue($self->issuekey, $self->user);
  $jira->transition_issue($self->issuekey, "In Arbeit");

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JC::Client::start - class implementing starting of an issue

=head1 VERSION

version 0.001

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

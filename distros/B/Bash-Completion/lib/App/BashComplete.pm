package App::BashComplete;
{
  $App::BashComplete::VERSION = '0.008';
}

# ABSTRACT: command line interface to Bash::Complete

use strict;
use warnings;
use Bash::Completion;
use Getopt::Long qw(GetOptionsFromArray);

############
# Attributes


sub opts { return $_[0]->{opts} }


sub cmd_line { return $_[0]->{cmd_line} }


#########
# Methods


sub new { return bless {opts => {}, cmd_line => []}, shift }



sub run {
  my $self = shift;

  # TODO: move commands to a plugin system

  # TODO: proper usage message
  return 1 unless my $cmd = $self->_parse_options(@_);

  return $self->setup    if $cmd eq 'setup';
  return $self->complete if $cmd eq 'complete';

  # TODO: proper unknown command message
  return 1;
}


#########
# Actions


sub complete {
  my ($self)   = @_;
  my $cmd_line = $self->cmd_line;
  my $plugin   = shift @$cmd_line;

  ## TODO: need a plugin
  return 1 unless $plugin;

  my $bc = Bash::Completion->new;
  my $req = $bc->complete($plugin, $cmd_line);

  return 1 unless $req;

  print "$_\n" for $req->candidates;
  return 0;
}



sub setup {
  my ($self) = @_;

  my $bc = Bash::Completion->new;
  print $bc->setup;

  return 0;
}


#######
# Utils

sub _parse_options {
  my $self = shift;

  my $cmd_line = $self->{cmd_line} = [@_];
  my $opts     = $self->{opts}     = {};

  my $ok = GetOptionsFromArray($cmd_line, $opts, 'help');

  # TODO: deal with !$ok
  return unless $ok;

  return shift(@$cmd_line);
}

1;




=pod

=head1 NAME

App::BashComplete - command line interface to Bash::Complete

=head1 VERSION

version 0.008

=head1 ATTRIBUTES

=head2 opts

Returns an HashRef with all the command line options used.

=head2 cmd_line

Returns a ArrayRef with the parts of the command line that could not be parsed as options.

=head1 METHODS

=head2 new

Creates a new empty instance.

=head2 run

Processes options, using both command line and arguments to run(), and
executes the proper action.

=head2 complete

=head2 setup

Collects all plugins, decides which ones should be activated, and generates the bash complete command lines for each one.

This allows you to setup your bash completion with only this:

    # Stick this into your .bashrc
    eval $( bash-complete setup )

The system will adjust to new plugins that you install via CPAN.

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__



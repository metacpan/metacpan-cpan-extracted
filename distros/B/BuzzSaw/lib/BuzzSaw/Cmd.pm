package BuzzSaw::Cmd; # -*-perl-*-
use strict;
use warnings;

# $Id: Cmd.pm.in 21390 2012-07-18 08:42:25Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21390 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Cmd.pm.in $
# $Date: 2012-07-18 09:42:25 +0100 (Wed, 18 Jul 2012) $

our $VERSION = '0.12.0';

use Log::Log4perl qw(:easy);

use Moose;
use MooseX::Types::Moose qw(Bool Maybe Str);

extends qw(MooseX::App::Cmd::Command);

has 'debug' => (
  traits      => ['Getopt'],
  isa         => Bool,
  is          => 'ro',
  default     => 0,
  cmd_aliases => 'D',
  documentation => 'Enable debug level logging',
);

has 'verbose' => (
  traits      => ['Getopt'],
  isa         => Bool,
  is          => 'ro',
  default     => 0,
  cmd_aliases => 'v',
  documentation => 'Enable verbose level logging',
);

has 'logconf' => (
  traits    => ['Getopt'],
  isa       => Maybe[Str],
  is        => 'ro',
  predicate => 'has_logconf',
  default   => '/etc/buzzsaw/log4perl.conf',
  documentation => 'Path to optional log4perl configuration file',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub BUILD {
  my ($self) = @_;

  return $self->preflight;
}

sub preflight {
  my ($self) = @_;

  if ( $self->has_logconf && -f $self->logconf ) {
    Log::Log4perl::init($self->logconf);
  } else {
    Log::Log4perl->easy_init($WARN);
  }

  my $logger = Log::Log4perl::get_logger(q{}); # Get the root logger

  # The secondary checks here are so that we avoid the possibility of
  # *lowering* the logging level if something higher was set in a
  # configuration file. The intention of these options is only to
  # enable the raising of logging levels where necessary.

  if ( $self->verbose && !$logger->is_info ) {
    $logger->level($INFO);
  }

  if ( $self->debug  && !$logger->is_debug ) {
    $logger->level($DEBUG);
  }

  return;
}

1;
__END__

=head1 NAME

BuzzSaw::Cmd - Super-class for BuzzSaw command line applications

=head1 VERSION

This documentation refers to BuzzSaw::Cmd version 0.12.0

=head1 SYNOPSIS

 package BuzzSaw::Cmd::Example;
 use Moose;

 extends 'BuzzSaw::Cmd';

 sub abstract { return q(Short help text for this app) }

 sub execute {
   my ( $self, $opt, $args ) = @_;

   ....
 }

=head1 DESCRIPTION

This is a super-class that should be extended by each class which
represents a BuzzSaw command-line application. This class allows easy
handling of command-line options and automates the generation of short
usage documentation.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

The following attributes are available for all modules which extend
this class and will be available as command-line options in the
applications. Any further attributes you add in a sub-class can also
be used as command-line options by applying the C<Getopt> trait, see
L<MooseX::Getopt> for details.

=over

=item verbose

Ensure the logging level is at least C<verbose>, this will enable INFO
messages.

=item debug

Ensure the logging level is at least C<debug>, this will enable DEBUG
and INFO messages.

=item logconf

BuzzSaw applications use the L<Log::Log4perl> module for all
logging. By default the applications will be configured to send
messages to stdout/stderr at the WARN level. If you wish to do
something more complicated you can pass in a path to a configuration
file and it will be used to initialise the logger. The default path is
C</etc/buzzsaw/log4perl.conf>

=back

=head1 SUBROUTINES/METHODS

=over

=item abstract

This method may be used to return a short string which describes the
purpose of the application. The abstract is used when auto-generating
help messages.

=item execute

This method does the actual work of the application and it MUST be
implemented.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need
L<MooseX::App::Cmd> and L<Log::Log4perl>

=head1 SEE ALSO

L<BuzzSaw>, L<MooseX::App::Cmd::Command>, L<App::Cmd::Command>, L<MooseX::Getopt>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

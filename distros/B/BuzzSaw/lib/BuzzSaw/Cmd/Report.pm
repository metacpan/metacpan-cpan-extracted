package BuzzSaw::Cmd::Report;  # -*-perl-*-
use strict;
use warnings;

# $Id: Report.pm.in 21690 2012-08-23 07:47:01Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21690 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Cmd/Report.pm.in $
# $Date: 2012-08-23 08:47:01 +0100 (Thu, 23 Aug 2012) $

our $VERSION = '0.12.0';

use BuzzSaw::Reporter;

use Moose;
use MooseX::Types::Moose qw(Bool Str);

extends 'BuzzSaw::Cmd';

has 'configfile' => (
  traits      => ['Getopt'],
  isa         => Str,
  is          => 'ro',
  predicate   => 'has_configfile',
  cmd_aliases => 'c',
  documentation => 'Load configuration from file',
);

has 'all' => (
  traits  => ['Getopt'],
  is      => 'ro',
  isa     => Bool,
  default => 0,
  documentation => 'Run all reports (even if already done for given period)',
);

has 'dryrun' => (
  traits  => ['Getopt'],
  is      => 'rw',
  isa     => Bool,
  default => 0,
  documentation => 'Dry-run only, do not actually run reports',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub abstract { return q{Generate reports on collected events} };

sub execute {
  my ( $self, $opt, $args ) = @_;

  my %args;
  $args{configfile} = $self->configfile if $self->has_configfile;
  $args{dryrun}     = 1                 if $self->dryrun;
  $args{all}        = 1                 if $self->all;

  my $reporter = BuzzSaw::Reporter->new_with_config(%args);

  $reporter->generate_reports(@{$args});

  return;
}

1;
__END__

=head1 NAME

BuzzSaw::Cmd::Report - BuzzSaw report generator

=head1 VERSION

This documentation refers to BuzzSaw::Cmd::Report version 0.12.0

=head1 SYNOPSIS

This module is not designed to be used directly. It is used by
L<App::BuzzSaw> to provide a C<buzzsaw> command-line application. The
command-line application works like:

% buzzsaw report [--configfile buzzsaw_report.yaml]

=head1 DESCRIPTION

This module extends the L<BuzzSaw::Cmd> class to provide a
command-line application which can be used to generate reports on
collected events. This module provides a light-weight wrapper around
the L<BuzzSaw:Reporter> module which is what does the actual data
processing.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

This module has one attribute which is accessible as a command-line
option.

=over

=item configfile

This is a string which specifies the name of the configuration file to
use when loading the L<BuzzSaw::Reporter> object. The default file is
C</etc/buzzsaw/reporter.yaml>, you only need to specify this option if
you want to use an alternative file.

=back

=head1 SUBROUTINES/METHODS

=over

=item abstract

This method may be used to return a short string which describes the
purpose of the application. The abstract is used when auto-generating
help messages.

=item execute

This method loads the new L<BuzzSaw::Reporter> object using the
C<new_with_config> method. It provides the ability to override the
values of the attributes which are accessible as command-line
options. It then calls the C<generate_reports> method which does the
real work.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need
L<MooseX::Types> and L<MooseX::App::Cmd>

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Cmd>, L<BuzzSaw::Reporter>, L<BuzzSaw::Report>, L<MooseX::App::Cmd::Command>, L<App::Cmd::Command>, L<MooseX::Getopt>

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

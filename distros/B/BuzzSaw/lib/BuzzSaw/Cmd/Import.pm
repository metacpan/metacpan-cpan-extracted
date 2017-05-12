package BuzzSaw::Cmd::Import;  # -*-perl-*-
use strict;
use warnings;

# $Id: Import.pm.in 21368 2012-07-17 11:18:36Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21368 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Cmd/Import.pm.in $
# $Date: 2012-07-17 12:18:36 +0100 (Tue, 17 Jul 2012) $

our $VERSION = '0.12.0';

use BuzzSaw::Importer;

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

has 'readall' => (
  traits      => ['Getopt'],
  isa         => Bool,
  is          => 'ro',
  default     => 0,
  cmd_aliases => 'r',
  documentation => 'Read all sources',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub abstract { return q{Import events of interest from log sources} };

sub execute {
  my ( $self, $opt, $args ) = @_;

  my %args;
  $args{readall}    = 1 if $self->readall;
  $args{configfile} = $self->configfile if $self->has_configfile;

  my $importer = BuzzSaw::Importer->new_with_config(%args);

  $importer->import_events;

  return;
}

1;
__END__

=head1 NAME

BuzzSaw::Cmd::Import - BuzzSaw log entry importer application

=head1 VERSION

This documentation refers to BuzzSaw::Cmd::Import version 0.12.0

=head1 SYNOPSIS

This module is not designed to be used directly. It is used by
L<App::BuzzSaw> to provide a C<buzzsaw> command-line application. The
command-line application works like:

% buzzsaw import [--readall] [--configfile buzzsaw_import.yaml]

=head1 DESCRIPTION

This module extends the L<BuzzSaw::Cmd> class to provide a
command-line application which can be used to import new log
entries. This module provides a light-weight wrapper around the
L<BuzzSaw::Importer> module which is what does the actual data
processing.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

This module has two attributes which are both accessible as
command-line options.

=over

=item configfile

This is a string which specifies the name of the configuration file to
use when loading the L<BuzzSaw::Importer> object. The default file is
C</etc/buzzsaw/importer.yaml>, you only need to specify this option if
you want to use an alternative file.

=item readall

This is a boolean value which controls whether to read all available
sources (no matter whether or not they have been previously
examined). The default is false.

=back

=head1 SUBROUTINES/METHODS

=over

=item abstract

This method may be used to return a short string which describes the
purpose of the application. The abstract is used when auto-generating
help messages.

=item execute

This method loads the new L<BuzzSaw::Importer> object using the
C<new_with_config> method. It provides the ability to override the
values of the attributes which are accessible as command-line
options. It then calls the C<import_events> method which does the real
work.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need
L<MooseX::Types> and L<MooseX::App::Cmd>

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Cmd>, L<BuzzSaw::Importer>, L<MooseX::App::Cmd::Command>, L<App::Cmd::Command>, L<MooseX::Getopt>

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

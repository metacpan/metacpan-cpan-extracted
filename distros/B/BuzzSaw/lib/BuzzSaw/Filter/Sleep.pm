package BuzzSaw::Filter::Sleep; # -*-perl-*-
use strict;
use warnings;

# $Id: Sleep.pm.in 23005 2013-04-04 06:42:45Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23005 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Filter/Sleep.pm.in $
# $Date: 2013-04-04 07:42:45 +0100 (Thu, 04 Apr 2013) $

our $VERSION = '0.12.0';

use Readonly;

use Moose;

with 'BuzzSaw::Filter', 'MooseX::Log::Log4perl';

no Moose;
__PACKAGE__->meta->make_immutable;

sub check {
  my ( $self, $event ) = @_;

  my @tags;
  my $accept = $BuzzSaw::Filter::VOTE_NO_INTEREST;
  if ( exists $event->{program} && $event->{program} eq 'lcfg-sleep' ) {
    push @tags, 'sleep';

    if ( $event->{message} eq 'Waking up' ) {
      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'acpi_wake';
    } elsif ( $event->{message} eq 'Going to sleep' ) {
      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'acpi_sleep';
    }

  }

  return ( $accept, @tags );
}

1;
__END__

=head1 NAME

BuzzSaw::Filter::Sleep - A BuzzSaw event filter for sleep log entries

=head1 VERSION

This documentation refers to BuzzSaw::Filter::Sleep version 0.12.0

=head1 SYNOPSIS

   my $filter = BuzzSaw::Filter::Sleep->new();

   while ( defined( my $line = $fh->getline ) ) {
     my %event = $parser->parse_line($line);

     my ( $accept, @tags ) = $filter->check(\%event);

     if ($accept) {
        # store log entry in DB
     }
   }

=head1 DESCRIPTION

This is a Moose class which provides a filter which implements the
BuzzSaw::Filter role. It is used to filter log entries and find those
associated with ACPI sleep. The module reports on
instances of ACPI acpi_sleep and acpi_wake. When an event is
accepted by the Sleep filter module it returns a C<sleep> tag along
with one of C<acpi_sleep> or C<acpi_wake>.

Note that this filter depends on the following two commands being
executed by the pm-utils package at the time of acpi_sleep or acpi_wake
respectively:

   /usr/bin/logger -t lcfg-sleep "Going to sleep"

   /usr/bin/logger -t lcfg-sleep "Waking up"

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item name

The short name of the module. The default is to use the final part of
the Perl module name lower-cased (e.g. the name of
C<BuzzSaw::Filter::Sleep> is C<sleep>).

=back

=head1 SUBROUTINES/METHODS

=over

=item ( $accept, @tags ) = $filter->check(\%event)

This method checks for log entries which are associated with sleep.
It does this by looking for lines where the
C<program> attribute is set to C<lcfg-sleep>. If that matches then it
looks to see if the message is "Waking up" or "Going to sleep".
If an event is accepted for storage then the
accept variable will be set to true and a set of tags will be returned
which contain C<sleep> and one of C<acpi_sleep> or C<acpi_wake>.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. This module implements the
L<BuzzSaw::Filter> Moose role.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Parser>

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

    Copyright (C) 2012-2013 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

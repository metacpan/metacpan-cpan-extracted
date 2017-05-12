package BuzzSaw::Report::Kernel; # -*-perl-*-
use strict;
use warnings;

# $Id: Kernel.pm.in 23030 2013-04-05 12:33:25Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23030 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Report/Kernel.pm.in $
# $Date: 2013-04-05 13:33:25 +0100 (Fri, 05 Apr 2013) $

our $VERSION = '0.12.0';

use Moose;

extends 'BuzzSaw::Report';

has '+tags' => (
    default => sub { [ 'segfault', 'oom', 'oops', 'panic' ] },
);

override 'process_events' => sub {
  my ( $self, @events ) = @_;

  my ( %segfault, %oom, %oops, %panic );
  for my $event (@events) {

    my $host = $event->hostname;

    my @tags = $event->search_related('tags')->all;

    for my $tag (@tags) {
      if ( $tag->name eq 'segfault' ) {
        $segfault{$host} ||= [];
        push @{ $segfault{$host} }, $event;
      } elsif ( $tag->name eq 'oom' ) {
        $oom{$host} ||= [];
        push @{ $oom{$host} }, $event;
      } elsif ( $tag->name eq 'oops' ) {
        $oops{$host} ||= [];
        push @{ $oops{$host} }, $event;
      } elsif ( $tag->name eq 'panic' ) {
        $panic{$host} ||= [];
        push @{ $panic{$host} }, $event;
      }
    }

  }

  my %results = (
    segfault => \%segfault,
    oom      => \%oom,
    oops     => \%oops,
    panic    => \%panic,
  );

  return %results;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

BuzzSaw::Report::Kernel - Generate BuzzSaw reports about kernel events

=head1 VERSION

This documentation refers to BuzzSaw::Report::Kernel version 0.12.0

=head1 SYNOPSIS

use BuzzSaw::Report;

my $report = BuzzSaw::Report::Kernel->new(
                   email_to => 'fred@example.org',
                   start    => 'yesterday',
                   end      => 'today',
);

$report->generate();

=head1 DESCRIPTION

This module provides the functionality to search the BuzzSaw database
for log events related to the Linux kernel. In particular it searches
for log entries related to kernel panics, oops, out-of-memory (OOM
killer) and segfaults. In the post-processing stage the events are
classified and grouped based on the additional attached tags. This is
intended to make it easier to generate reports.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

This class does not have any attributes which are not part of the
L<BuzzSaw::Report> parent class. It does override the following:

=over

=item tags

The default value for this attribute is set to a list containing the
C<kernel> tag.

=back

=head1 SUBROUTINES/METHODS

This class does not have any subroutines or methods which are not part
of the L<BuzzSaw::Report> parent class. It does override the
following:

=over

=item %results = $report->process_events(@events)

This method overrides that provided by the parent class. It is used to
group the events based on any additional attached tags (e.g. C<panic>,
C<oops>, C<oom> and C<segfault>). The results hash returned has an
entry for each of these tags where the value for each is a reference
to a hash which is keyed on hostname. The values for this secondary
hash are a reference to a list of kernel events of the relevant type
found for the hostname.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Report>

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



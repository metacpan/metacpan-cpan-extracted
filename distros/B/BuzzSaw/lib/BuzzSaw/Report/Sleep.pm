package BuzzSaw::Report::Sleep; # -*-perl-*-
use strict;
use warnings;

# $Id: Sleep.pm.in 23030 2013-04-05 12:33:25Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23030 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Report/Sleep.pm.in $
# $Date: 2013-04-05 13:33:25 +0100 (Fri, 05 Apr 2013) $

our $VERSION = '0.12.0';

use Moose;

extends 'BuzzSaw::Report';

has '+program' => (
    default => 'lcfg-sleep',
);

has '+tags' => (
    default => sub { ['acpi_wake','acpi_sleep'] },
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

BuzzSaw::Report::Sleep - Generate BuzzSaw reports about ACPI sleep events

=head1 VERSION

This documentation refers to BuzzSaw::Report::Sleep version 0.12.0

=head1 SYNOPSIS

use BuzzSaw::Report::Sleep;

my $report = BuzzSaw::Report::Sleep->new(
                   email_to => 'fred@example.org',
                   start    => 'yesterday',
                   end      => 'today',
);

$report->generate();

=head1 DESCRIPTION

This module provides the functionality to search the BuzzSaw database
for log events related to ACPI sleep. It searches for log entries
corresponding to the start and the end of ACPI sleep on machines using
the LCFG sleep component.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

This class does not have any attributes which are not part of the
L<BuzzSaw::Report> parent class. It does not override any attributes
of the parent class.

=head1 SUBROUTINES/METHODS

This class does not have any subroutines or methods which are not part
of the L<BuzzSaw::Report> parent class. It does not override any
subroutines or methods of the parent class.

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



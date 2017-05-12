package BuzzSaw::Parser; # -*-perl-*-
use strict;
use warnings;

# $Id: Parser.pm.in 21360 2012-07-16 13:46:29Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21360 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Parser.pm.in $
# $Date: 2012-07-16 14:46:29 +0100 (Mon, 16 Jul 2012) $

our $VERSION = '0.12.0';

use Moose::Role;

requires 'parse_line';

no Moose::Role;

1;
__END__

=head1 NAME

BuzzSaw::Parser - A Moose role which defines the BuzzSaw parser interface

=head1 VERSION

This documentation refers to BuzzSaw::Parser version 0.12.0

=head1 SYNOPSIS

package BuzzSaw::Parser::Example;
use Moose;

with 'BuzzSaw::Parser';

sub parse_line {
  my ( $self, $line ) = @_;
  ...

  return %event;
}

=head1 DESCRIPTION

This is a Moose role which is used to define the required interface
for a BuzzSaw parser module. The parser modules are used to split a
log entry into separate parts, e.g. date, program, pid,
message. Mostly this is a case of being able to handle the particular
date/time format being used in the log entry (e.g. RFC3339).

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

There are no attributes in this role.

=head1 SUBROUTINES/METHODS

Any class which implements this role must provide the following
method.

=over

=item %results = $parser->parse_line($log_entry)

Any class which implements this role must provide an implementation of
the C<parse_line> method. This method will be called for every entry
found (so make sure the code is not too slow). It takes a string and
returns a hash which contains the details of the various parts of the
entry.

The following date and time attributes must always be set in the
returned hash: C<year>, C<month>, C<day>, C<hour>, C<minute>,
C<second>. If a time-zone is specified in the log entry it should be
returned with the key C<time_zone>. These field names must match with
the L<DateTime> attributes.

The C<message> attribute must always be defined (even if it is just an
empty string). The C<program> and C<pid> attributes are optional.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Filter>, L<BuzzSaw::Parser::RFC3339>

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

package BuzzSaw::Parser::RFC3339; # -*-perl-*-
use strict;
use warnings;

# $Id: RFC3339.pm.in 22935 2013-03-28 12:51:19Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22935 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Parser/RFC3339.pm.in $
# $Date: 2013-03-28 12:51:19 +0000 (Thu, 28 Mar 2013) $

our $VERSION = '0.12.0';

use Readonly;

use Moose;

with 'BuzzSaw::Parser', 'MooseX::Log::Log4perl';

no Moose;
__PACKAGE__->meta->make_immutable;

# Regexp1. program and PID, followed by optional colon

Readonly my $rfc3339_re =>
    qr{
       (?<year>\d{4})                      # year
       -
       (?<month>\d{2})                     # month
       -
       (?<day>\d{2})                       # day
       T
       (?<hour>\d{2})                      # hour
       :
       (?<minute>\d{2})                    # minute
       :
       (?<second>\d{2})                    # second
       (?<nanosecond>\.\d+)?               # nanosecond
       (?<time_zone>Z|(?:[+-]\d{2}:\d{2})) # time_zone
      }xo;

Readonly my $prog_re1 =>
    qr{
       (?<program>[^:\[]+)
       \[
       (?<pid>\d+)
       (?:\]|(?=\s)) # closing bracket or next char is a space
       :?
      }xo;

# Regexp2. program followed by mandatory colon (no PID)

Readonly my $prog_re2 =>
    qr{
       (?<program>[^:]+)
       :
      }xo;

Readonly my $prog_full_re =>
    qr{
       ($prog_re1|$prog_re2)
       \s+
       (?<message>.+)
      }xo;

sub parse_line {
    my ( $self, $line ) = @_;

    # These field names match those used by the DateTime module

    my %results;

    my ( $time, $hostname, $message ) = split q{ }, $line, 3;

    $results{hostname} = $hostname;
    $results{message}  = defined $message  ? $message  : q{};

    if ( $time =~ m{^$rfc3339_re$}o ) {
        %results = ( %results, %+ );

        if ( !defined $results{time_zone} || $results{time_zone} eq 'Z' ) {
            $results{time_zone} = 'UTC';
        } else {
            $results{time_zone} =~ s/://;
        }

        if ( defined $results{nanosecond} ) {
            $results{nanosecond} *= 1000000000;
        } else {
            $results{nanosecond} = 0;
        }

    } else {
        die "Failed to parse RFC3339 timestamp in line: $line\n";
    }

    # Attempt to acquire more information from the message

    if ( $results{message} =~ m{^$prog_full_re$}o ) {
        %results = ( %results, %+ );
    }

    return %results;
}


1;
__END__

=head1 NAME

BuzzSaw::Parser::RFC3339 - BuzzSaw parser for log entries with the RFC3339 dates

=head1 VERSION

This documentation refers to BuzzSaw::Parser::RFC3339 version 0.12.0

=head1 SYNOPSIS

use BuzzSaw::Parser::RFC3339;

my $parser = BuzzSaw::Parser::RFC3339->new();

while (defined (my $line = $fh->getline) ) {
  my %event = $parser->parse_line($line);
}

=head1 DESCRIPTION

This is a Moose class which provides a parser which implements the
BuzzSaw::Parser role. It can handle log entries that use the RFC3339
date format (e.g. looks like C<2013-03-28T11:57:30.025350+00:00>. The
parser splits a line into separate parts, e.g. date, program, pid,
message.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

There are no attributes in this class.

=head1 SUBROUTINES/METHODS

=over

=item %results = $parser->parse_line($log_entry)

This method takes a log entry line as a string and returns a hash
which contains the details of the various parts of the entry.

The following date and time attributes will be specified in the
returned hash: C<year>, C<month>, C<day>, C<hour>, C<minute>,
C<second>. If a time-zone is specified in the log entry it will be
returned with the key C<time_zone>. These field names match with the
L<DateTime> attributes.

The C<message> attribute will always be defined (even if it is just an
empty string). The C<program> and C<pid> attributes are optional.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. This module implements the
L<BuzzSaw::Parser> Moose role.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Filter>

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

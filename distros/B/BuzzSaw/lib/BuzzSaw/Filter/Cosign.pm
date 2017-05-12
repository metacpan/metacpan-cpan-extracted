package BuzzSaw::Filter::Cosign; # -*-perl-*-
use strict;
use warnings;

# $Id: Cosign.pm.in 23005 2013-04-04 06:42:45Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23005 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Filter/Cosign.pm.in $
# $Date: 2013-04-04 07:42:45 +0100 (Thu, 04 Apr 2013) $

our $VERSION = '0.12.0';

use Readonly;

Readonly my $re_ipv4 => qr{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}}o;

Readonly my $re_register => qr{^REGISTER\s+
                                (?<user>\S+)\s+
                                (?<realm>\S+)\s+
                                (?<address>$re_ipv4)\s+
                                (?<service>\S+)
                               $}xo;

use Moose;

with 'BuzzSaw::Filter', 'MooseX::Log::Log4perl';

sub check {
  my ( $self, $event ) = @_;

  my @tags;
  my $accept = $BuzzSaw::Filter::VOTE_NO_INTEREST;
  if ( exists $event->{program} && $event->{program} eq 'cosignd' ) {
    push @tags, ( 'cosign', 'auth' );

    if ( $event->{message} =~ $re_register ) {
      $event->{userid} = $+{user};
      $event->{extra_info}{cosign_service} = $+{service};
      $event->{extra_info}{source_address} = $+{address};

      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'auth_success';
    }

  }

  return ( $accept, @tags );
}

1;
=head1 NAME

BuzzSaw::Filter::Cosign - A BuzzSaw event filter for Cosign log entries

=head1 VERSION

This documentation refers to BuzzSaw::Filter::Cosign version 0.12.0

=head1 SYNOPSIS

   my $filter = BuzzSaw::Filter::Cosign->new();

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
associated with the cosign daemon. An event will be accepted for
storage if it is related to a login being registered. When an event is
accepted by the Cosign filter module it returns C<cosign> and C<auth>
and C<auth_success> tags.

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
C<BuzzSaw::Filter::Cosign> is C<cosign>).

=back

=head1 SUBROUTINES/METHODS

=over

=item ( $accept, @tags ) = $filter->check(\%event)

This method checks for log entries which are associated with Cosign
daemon logins which have been accepted.

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

This module only accepts Cosign registration entries which refer to
IPv4 addresses.

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

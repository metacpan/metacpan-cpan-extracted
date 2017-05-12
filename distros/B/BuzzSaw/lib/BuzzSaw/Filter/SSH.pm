package BuzzSaw::Filter::SSH; # -*-perl-*-
use strict;
use warnings;

# $Id: SSH.pm.in 23005 2013-04-04 06:42:45Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23005 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Filter/SSH.pm.in $
# $Date: 2013-04-04 07:42:45 +0100 (Thu, 04 Apr 2013) $

our $VERSION = '0.12.0';

use Readonly;

Readonly my $re_accepted => qr{^Accepted\s+
                                (?<method>\S+)\s+
                                for\s+
                                (?<user>\S+)\s+
                                from\s+
                                (?<address>\S+)}xo;

Readonly my $re_failed  => qr{^Failed\s+
                                (?<method>\S+)\s+
                                for\s+
                                (invalid\s+user\s+)?
                                (?<user>\S+)\s+
                                from\s+
                                (?<address>\S+)}xo;

use Moose;

with 'BuzzSaw::Filter', 'MooseX::Log::Log4perl';

sub check {
  my ( $self, $event ) = @_;

  my @tags;
  my $accept = $BuzzSaw::Filter::VOTE_NO_INTEREST;
  if ( exists $event->{program} && $event->{program} eq 'sshd' ) {
    push @tags, ( 'ssh', 'auth' );

    if ( $event->{message} =~ $re_accepted ) {
      $event->{userid} = $+{user};
      $event->{extra_info}{source_address} = $+{address};
      $event->{extra_info}{auth_method}    = $+{method};

      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'auth_success';
    } elsif ( $event->{message} =~ $re_failed ) {
      $event->{userid} = $+{user};
      $event->{extra_info}{source_address} = $+{address};
      $event->{extra_info}{auth_method}    = $+{method};

      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'auth_failure';
    }

  }

  return ( $accept, @tags );
}

1;
__END__

=head1 NAME

BuzzSaw::Filter::SSH - A BuzzSaw event filter for SSH log entries

=head1 VERSION

This documentation refers to BuzzSaw::Filter::SSH version 0.12.0

=head1 SYNOPSIS

   my $filter = BuzzSaw::Filter::SSH->new();

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
associated with the SSH daemon. An event will be accepted for storage
if it is related to a login being accepted or failed. When an event is
accepted by the SSH filter module it returns C<ssh> and C<auth> tags
along with one of C<auth_success> or C<auth_failure>.

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
C<BuzzSaw::Filter::SSH> is C<ssh>).

=back

=head1 SUBROUTINES/METHODS

=over

=item ( $accept, @tags ) = $filter->check(\%event)

This method checks for log entries which are associated with SSH
daemon logins which have either been accepted or failed.

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

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

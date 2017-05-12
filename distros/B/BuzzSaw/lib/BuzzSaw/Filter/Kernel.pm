package BuzzSaw::Filter::Kernel; # -*-perl-*-
use strict;
use warnings;

# $Id: Kernel.pm.in 23005 2013-04-04 06:42:45Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23005 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Filter/Kernel.pm.in $
# $Date: 2013-04-04 07:42:45 +0100 (Thu, 04 Apr 2013) $

our $VERSION = '0.12.0';

use Readonly;

Readonly my $re_segfault => qr{segfault}io;
Readonly my $re_oom      => qr{^(.+ invoked oom-killer|Out of memory|Killed process)}io;
Readonly my $re_panic    => qr{^(kernel panic |panic occurred)}io;
Readonly my $re_oops     => qr{^(Oops:|BUG:|kernel BUG|Unable to handle) }io;

use Moose;

with 'BuzzSaw::Filter', 'MooseX::Log::Log4perl';

no Moose;
__PACKAGE__->meta->make_immutable;

sub check {
  my ( $self, $event ) = @_;

  my @tags;
  my $accept = $BuzzSaw::Filter::VOTE_NO_INTEREST;
  if ( exists $event->{program} && $event->{program} eq 'kernel' ) {
    push @tags, 'kernel';

    if ( $event->{message} =~ $re_segfault ) {
      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'segfault';
    } elsif ( $event->{message} =~ $re_oom ) {
      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'oom';
    } elsif ( $event->{message} =~ $re_panic ) {
      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'panic';
    } elsif ( $event->{message} =~ $re_oops ) {
      $accept = $BuzzSaw::Filter::VOTE_KEEP;
      push @tags, 'oops';
    }

  }

  return ( $accept, @tags );
}

1;
__END__

=head1 NAME

BuzzSaw::Filter::Kernel - A BuzzSaw event filter for kernel log entries

=head1 VERSION

This documentation refers to BuzzSaw::Filter::Kernel version 0.12.0

=head1 SYNOPSIS

   my $filter = BuzzSaw::Filter::Kernel->new();

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
associated with the Linux kernel. The module attempts to spot
important issues, it currently supports checking for segfaults,
Out-Of-Memory (OOM) issues, kernel panics and oops. When an event is
accepted by the Kernel filter module it returns a C<kernel> tag along
with one of C<segfault>, C<oops>, C<oom> or C<panic>.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

There are no attributes in this class.

=head1 SUBROUTINES/METHODS

=over

=item ( $accept, @tags ) = $filter->check(\%event)

This method checks for log entries which are associated with important
kernel issues. It does this by firstly looking for lines where the
C<program> attribute is set to C<kernel>. If that matches then it
looks checks the message to see if there is evidence of a segfault,
oom, oops or panic. If an event is accepted for storage then the
accept variable will be set to true and a set of tags will be returned
which contain C<kernel> and one of C<segfault>, C<oops>, C<oom> or
C<panic>.

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

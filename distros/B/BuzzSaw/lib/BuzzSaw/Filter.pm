package BuzzSaw::Filter; # -*-perl-*-
use strict;
use warnings;

# $Id: Filter.pm.in 22947 2013-03-29 11:28:39Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22947 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Filter.pm.in $
# $Date: 2013-03-29 11:28:39 +0000 (Fri, 29 Mar 2013) $

our $VERSION = '0.12.0';

use Readonly;

Readonly our $VOTE_KEEP        => 1;
Readonly our $VOTE_NO_INTEREST => 0;
Readonly our $VOTE_NEUTRAL     => -1;

use Moose::Role;

use MooseX::Types::Moose qw(Str);

requires 'check';

has 'name' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  default  => sub {
    my $class = shift @_;
    my $name = ( split /::/, $class->meta->name )[-1];
    return $name;
  },
);

no Moose::Role;

1;
__END__

=head1 NAME

BuzzSaw::Filter - A Moose role which defines the BuzzSaw filter interface

=head1 VERSION

This documentation refers to BuzzSaw::Filter version 0.12.0

=head1 SYNOPSIS

package BuzzSaw::Filter::Example;
use Moose;

with 'BuzzSaw::Filter';

sub check {
  my ($self, $event) = @_;
  ...
}

=head1 DESCRIPTION

This is a Moose role which is used to define the required interface
for a BuzzSaw filter module. The filter modules are used to decide on
whether an event is of interest and should be stored into the
database. The module can also return a set of tags which are then
associated with the event. For example, when an event is accepted by
the Kernel filter module it returns a C<kernel> tag along with one of
C<segfault>, C<oops>, C<oom> or C<panic>.

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
C<BuzzSaw::Filter::UserClassifier> is C<userclassifier>).

=back

=head1 SUBROUTINES/METHODS

=over

=item ( $accept, @tags ) = $filter->check(\%event, $votes, $results )

Any class which implements this role must provide an implementation of
the C<check> method. This method will be called for every entry found
(so make sure the code is not too slow). It takes a reference to a
hash of event attributes produced by parsing the log entry. It will
also be passed the current number of votes from other filters in the
stack and a reference to an array of the results from any previous
decisions. Each entry in the stack of results is a pair of
(name,vote). This makes it possible to tailor processing later in the
stack based on previous decisions.

The method returns an integer value which specifies whether or not the
entry should be stored, there are 3 scenarios. (1) If the returned
value is positive the entry and tags will be stored. (2) If the
returned value is zero the entry will not be stored unless another
filter in the stack expresses interest, any tags returned will be
totally ignored. (3) If the returned value is negative then the entry
will not be stored unless another filter in the stack expresses
interest BUT the tags will be retained and stored if the final
decision is to store the entry. This makes it possible to do
additional post-processing which does not alter the results from the
previous filters. For instance, the UserClassifier filter adds a user
type tag for any filter which sets the C<userid> field (e.g. SSH and
Cosign).

It also, optionally, returns a list of tags which should be associated
with the stored event.

For the log entry, the following date and time attributes will always
be defined: C<year>, C<month>, C<day>, C<hour>, C<minute>, C<second>,
C<time_zone>.

The C<message> attribute will be defined. The C<program> and C<pid>
attributes might be defined, most entries have C<program> but far
fewer have C<pid>, neither is guaranteed to be set.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Parser>, L<BuzzSaw::Filter::Kernel>

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

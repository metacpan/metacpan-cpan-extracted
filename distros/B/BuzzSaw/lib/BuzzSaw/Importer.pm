package BuzzSaw::Importer; # -*-perl-*-
use strict;
use warnings;

# $Id: Importer.pm.in 23002 2013-04-04 06:36:41Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23002 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Importer.pm.in $
# $Date: 2013-04-04 07:36:41 +0100 (Thu, 04 Apr 2013) $

our $VERSION = '0.12.0';

use BuzzSaw::DB;
use BuzzSaw::Types qw(BuzzSawDB BuzzSawFilterList BuzzSawDataSourceList);
use DateTime ();
use English qw(-no_match_vars);

use Readonly;

Readonly my @DATETIME_FIELDS => qw/year month day hour minute second nanosecond time_zone/;

use Moose;
use MooseX::Types::Moose qw(Bool);

with 'MooseX::Log::Log4perl', 'MooseX::SimpleConfig';

has '+configfile' => (
  default => '/etc/buzzsaw/importer.yaml',
);

has 'sources' => (
  traits   => ['Array'],
  isa      => BuzzSawDataSourceList,
  is       => 'ro',
  coerce   => 1,
  required => 1,
  handles  => {
    'list_sources' => 'elements',
  },
);

has 'filters' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => BuzzSawFilterList,
  coerce   => 1,
  required => 1,
  lazy     => 1,
  default  => sub { [] },
  handles  => {
    'list_filters' => 'elements',
    'has_filters'  => 'count',
  },
);

has 'db' => (
  is       => 'rw',
  isa      => BuzzSawDB,
  coerce   => 1,
  required => 1,
  lazy     => 1,
  default  => sub { BuzzSaw::DB->new_with_config() },
);

has 'readall' => (
  is      => 'ro',
  isa     => Bool,
  default => 0,
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub import_events {
  my ($self) = @_;

  my $db = $self->db;

  my @filters = $self->list_filters;

  # If there are no filters we will accept ALL entries

  my $accept_default = $self->has_filters ? 0 : 1;

  if ( $self->log->is_debug ) {
    $self->log->debug("accept default is: $accept_default");
  }

  my $examined_count = 0;
  my $accepted_count = 0;

  for my $source ( $self->list_sources ) {

    $source->readall(1) if $self->readall;
    $source->db($db);

    $source->reset();

    while ( defined ( my $entry = $source->next_entry ) ) {
      $examined_count++;

      # ignore empty entries
      if ( $entry =~ m/^\s*$/ ) {
        next;
      }

      my $digest = $source->checksum_data($entry);

      my %event = ( raw => $entry, digest => $digest );

      my $seen = $self->db->check_event_seen(\%event);

      if ($seen) {
        next;
      }

      # Parsing

      my %results = eval { $source->parser->parse_line($entry) };
      if ($EVAL_ERROR) {
        $self->log->error("Parse failure: $EVAL_ERROR");
        next;
      }

      %event = ( %results, %event );

      # Filtering

      my $votes = $accept_default;

      if ( $self->has_filters ) {

        my @results;
        my %all_tags;
        for my $filter (@filters) {
          my ( $accept, @tags ) = $filter->check( \%event,
                                                  $votes, \@results );

          push @results, [ $filter->name => $accept ];

          if ( $accept == $BuzzSaw::Filter::VOTE_KEEP ) {
            $votes += 1;

            for my $tag (@tags) {
              $all_tags{$tag} = 1;
            }
          } elsif ( $accept == $BuzzSaw::Filter::VOTE_NEUTRAL ) {

            for my $tag (@tags) {
              $all_tags{$tag} = 1;
            }
          }

        }

        $event{tags} = [keys %all_tags];
      }

      # Registering

      if ($votes) {
        $accepted_count++;

        # Convert the various date fields into a DateTime
        # object which DBIx::Class will format correctly for
        # the DB.

        my %date;
        for my $key (@DATETIME_FIELDS) {
          $date{$key} = $event{$key};
        }
        $event{logtime} = DateTime->new( %date );

        $db->register_event(\%event);
      }

    }
  }

  $self->log->info("Examined $examined_count entries, accepted $accepted_count");

  return;
}

1;
__END__

=head1 NAME

BuzzSaw::Importer - Imports log entries of interest from data sources

=head1 VERSION

This documentation refers to BuzzSaw::Importer version 0.12.0

=head1 SYNOPSIS

  use BuzzSaw::Importer;
  use BuzzSaw::DataSource::Files;

  my $source = BuzzSaw::DataSource::Files->new(
    parser      => "RFC3339",
    names       => [qr/^.*\.log(-\d+)?$/],
    directories => [@ARGV],
    recursive   => 1,
  );

  my $importer = BuzzSaw::Importer->new(
    sources   => [$source],
    filters   => ["Kernel"],
  );

  $importer->import_events;

=head1 DESCRIPTION

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item sources

This is a reference to a list of objects which implement the
L<BuzzSaw::DataSource> role. You must specify at least one data
source. These sources will be queried for entries until all sources
are exhausted.

Each element in the list can be expressed as an array reference where
the first element is the name of the class of object to be
created. Any subsequent elements are then passed in as arguments for
the object creation. This makes it possible to do something like this:

  my $importer = BuzzSaw::Importer->new( sources => [
                   [ Files => {
                           names       => ["*.log"],
                           directories => ["/var/log"],
                           recursive   => 0 } ],
                   ],
                 );

This is primarily useful for saving the complete configuration into a
file for later use with the C<new_with_config> method.

=item filters

This is a reference to a list of objects which implement the
L<BuzzSaw::Filter> role. Each filter is called in sequence for each
log entry to find events of interest. If any filter expresses interest
in the event then it will be stored into the database. Note that it is
possible to do fairly complex filtering by careful sequencing of the
filter order, this allows a filter to rely on the results of those
earlier in the stack.

There are 3 possible scenarios for results returned by a filter: (1)
If the returned value is positive the entry and tags will be
stored. (2) If the returned value is zero the entry will not be stored
unless another filter in the stack expresses interest, any tags
returned will be totally ignored. (3) If the returned value is
negative then the entry will not be stored unless another filter in
the stack expresses interest BUT the tags will be retained and stored
if the final decision is to store the entry. This makes it possible to
do additional post-processing which does not alter the results from
the previous filters. For instance, the UserClassifier filter adds a
user type tag for any filter which sets the C<userid> field (e.g. SSH
and Cosign).

If you do not specify any filters then ALL events will be
automatically accepted and the entire data set will be stored into the
database.

If an element in the list passed in is a string then it is considered
to be a class name in the BuzzSaw::Filter namespace. Short names are
allowed, e.g. passing in C<Kernel> would result in a new
L<BuzzSaw::Filter::Kernel> object being created.

=item db

This is a reference to the L<BuzzSaw::DB> object which will be used to
store any events of interest. It will also be passed into the various
data source objects so that it can be used to register parsed log
sources, check for previously seen sources, etc.

It is possible to specify this as a string in which case that will be
considered to be a configuration file name and it will be handed off
to the C<new_with_config> method for the L<BuzzSaw::DB> class.

If you do not specify the L<BuzzSaw::DB> object then a new one will be
created by calling the C<new_with_config> method (which will use the
default configuration file name for that class).

=item readall

This is a boolean value which controls whether or not all files should
be read. If it is set to C<true> (i.e. a value of 1 - one) then the
code which attempts to avoid re-reading previously seen files will not
be used. The default value is C<false> (i.e. a value of 0 -
zero). When this value is set to true it will be set to true for all
the data sources, this makes it easier to override globally. When it
is false then the specific setting for the data source will be used.

=back

=head1 SUBROUTINES/METHODS

This class has the following methods:

=over

=item $importer = BuzzSaw::Importer->new()

This will create a new BuzzSaw::Importer object. You will need to
specify, at least, a data source.

=item $importer = BuzzSaw::Importer->new_with_config()

This will create a new BuzzSaw::Impoter object using the attribute
values stored in the configuration file. A filename maybe be
specified, if not the default value will be used. The value for any
attribute can be overridden.

=item $importer->import_events

This is the method which does all the work. It works through the
streams of entries from each data source. Firstly the SHA-256 digest
is calculated for each event, any event which has previously been seen
will then be ignored. For new events they are parsed into their
constituent parts using the relevant L<BuzzSaw::Parser>. The parsed
event is then passed through all the specified L<BuzzSaw::Filter>
objects. If the event is of interest it is then stored using the
L<BuzzSaw::DB> object.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need
L<MooseX::Types>, L<MooseX::Log::Log4perl> and
L<MooseX::SimpleConfig>.

This module also requires the L<DateTime> and L<Readonly> modules.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::DB>, L<BuzzSaw::DataSource>,
L<BuzzSaw::Parser>, L<BuzzSaw::Filter>

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

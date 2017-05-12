package BuzzSaw::Cmd::AnonymiseData;  # -*-perl-*-
use strict;
use warnings;

# $Id: AnonymiseData.pm.in 22461 2013-02-01 11:30:50Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22461 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Cmd/AnonymiseData.pm.in $
# $Date: 2013-02-01 11:30:50 +0000 (Fri, 01 Feb 2013) $

our $VERSION = '0.12.0';

use BuzzSaw::DB;

use Moose;
use MooseX::Types::Moose qw(Bool Str);

extends 'BuzzSaw::Cmd';

with 'MooseX::Log::Log4perl';

has 'db' => (
  traits  => ['Getopt'],
  is       => 'ro',
  isa      => Str,
  required => 1,
  default  => '/etc/buzzsaw/db_anonymiser.yaml',
  documentation => 'Database connection configuration file',
);

has 'max_age' => (
  traits  => ['Getopt'],
  is       => 'ro',
  isa      => Str,
  required => 1,
  default  => '26 weeks',
  documentation => 'Maximum permitted age of event logs',
);

has 'dryrun' => (
  traits  => ['Getopt'],
  is      => 'rw',
  isa     => Bool,
  default => 0,
  documentation => 'Dry-run only, do not actually modify the DB',
);

after 'preflight' => sub {
  my $self = shift @_;

  # When a dry-run has been requested we need to raise the logging
  # level if it is not already high enough to show info messages.

  if ( $self->dryrun ) {
    my $logger = $self->logger;

    if ( !$logger->is_info ) {
      $logger->level($Log::Log4perl::INFO);
    }
  }

  return;
};

no Moose;
__PACKAGE__->meta->make_immutable;

sub abstract { return q{Anonymises all out-of-date event logs} };

sub execute {
  my ( $self, $opt, $args ) = @_;

  my $db = BuzzSaw::DB->new_with_config( configfile => $self->db );

  my $schema = $db->schema;
  my $events_rs = $schema->resultset('Event');

  # We want all events older than the specified age which have values
  # for any of the raw, message and userid fields.

  # This is a bit weird but is how DBIx::Class supports arbitrary
  # WHERE queries with binding of placeholder values.

  # We cast the placeholder from a string to an interval since there
  # is no support in DBI for expressing it the other way around.

  # This is done as two separate result sets since after this we want
  # to look for any extra_info data associated with all old
  # events. There may be extra_info records associated with event
  # records which do not have raw, message or userid data.

  my $old_events = $events_rs->search( {
    logdate => { '<' => \ ['current_date - ?::interval',
                          [ plain_value => $self->max_age ] ] },
  } );

  my $old_with_data = $old_events->search( {
    -or => [
       message => { '!=', ''    },
       raw     => { '!=', ''    },
       userid  => { '!=', undef },
    ],
  } );

  if ( $self->debug ) {
    my $count = $old_with_data->count();
    $self->log->debug("Found $count old events containing personal data");
  }

  if ( $self->dryrun ) {
    my $count = $old_with_data->count();
    $self->log->info("Dry-Run: Would anonymise $count old event records");
  } else {
    $schema->txn_begin;

    my $ok = eval {
      $old_with_data->update( { raw     => q{},
                                message => q{},
                                userid  => undef } );
    };

    if ( !$ok || $@ ) {
      $schema->txn_rollback;
      $self->log->logdie("Failed to anonymise old events: $@");
    } else {
      $schema->txn_commit;
      if ( $self->debug ) {
        $self->log->debug("Successfully anonymised old events");
      }
    }
  }

  my $info_rs = $schema->resultset('ExtraInfo');

  # Find any extra_info records associated with events which are older
  # than the maximum permitted age. This uses a sub-query for efficiency.

  my $old_info = $info_rs->search( {
    event => { -in => $old_events->get_column('id')->as_query },
  });

  if ( $self->debug ) {
    my $delete_count = $old_info->count;
    $self->log->debug("Found $delete_count old info records");
  }

  if ( $self->dryrun ) {
    my $delete_count = $old_info->count;
    $self->log->info("Dry-Run: Would delete $delete_count info records");
  } else {
    $schema->txn_begin;

    my $ok = eval {
      $old_info->delete;
    };

    if ( !$ok || $@ ) {
      $schema->txn_rollback;
      $self->log->logdie("Failed to delete old information: $@");
    } else {
      $schema->txn_commit;
      if ( $self->debug ) {
        $self->log->debug("Successfully anonymised old information");
      }
    }
  }

  return;
}

1;
__END__

=head1 NAME

BuzzSaw::Cmd::AnonymiseData - BuzzSaw data anonymiser

=head1 VERSION

This documentation refers to BuzzSaw::Cmd::AnonymiseData version 0.12.0

=head1 SYNOPSIS

This module is not designed to be used directly. It is used by
L<App::BuzzSaw> to provide a C<buzzsaw> command-line application. The
command-line application works like:

% buzzsaw anonymisedata [--max_age='26 weeks'] [--dry-run] [--db db_conf.yaml]

=head1 DESCRIPTION

This module extends the L<BuzzSaw::Cmd> class to provide a
command-line application which can be used to anonymise old
data. Given a maximum permitted age for the personal information (the
default is 26 weeks) this tool will delete information in the C<raw>,
C<message> and C<userid> fields of the BuzzSaw C<event> table. It will
also delete all C<extra_info> records associated with old events.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item max_age

This is the maximum permitted age for records containing personal
information. The default is C<26 weeks>, you can use anything which
the PostgreSQL C<interval> type supports (e.g. C<190 days>).

=item dry_run

If this option is enabled then the tool will not actually change
anything in the database.  It will just print out some information
detailing what records would be altered.

=item db

This is a string which specifies the name of the configuration file to
use when loading the L<BuzzSaw::DB> object. The default file is
C</etc/buzzsaw/db_writer.yaml>, you only need to specify this option
if you want to use an alternative file.

=back

=head1 SUBROUTINES/METHODS

=over

=item abstract

This method may be used to return a short string which describes the
purpose of the application. The abstract is used when auto-generating
help messages.

=item execute

This method uses the L<BuzzSaw::DB> module to find all events older
than the specified maximum age. Any events which are too old and have
values for any of the C<raw>, C<message> or C<userid> fields will be
anonymised. Also any C<extra_info> records associated with these old
events will be deleted.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need
L<MooseX::Types> and L<MooseX::App::Cmd>

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Cmd>, L<BuzzSaw::DB>, L<MooseX::App::Cmd::Command>, L<App::Cmd::Command>, L<MooseX::Getopt>

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

    Copyright (C) 2013 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

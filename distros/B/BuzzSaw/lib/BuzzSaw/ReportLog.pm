package BuzzSaw::ReportLog; # -*-perl-*-
use strict;
use warnings;

# $Id: ReportLog.pm.in 21695 2012-08-23 15:07:50Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21695 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/ReportLog.pm.in $
# $Date: 2012-08-23 16:07:50 +0100 (Thu, 23 Aug 2012) $

our $VERSION = '0.12.0';

use File::Spec ();
use File::Temp ();
use Text::Diff ();
use YAML::Syck ();

my @REPORT_TYPES = qw/hourly daily weekly monthly/;

use Moose;
use MooseX::Types::Moose qw(HashRef Bool Int Str);

has '_initialising' => (
  is       => 'rw',
  isa      => Bool,
  default  => 1,
  init_arg => undef,
);

has '_changes' => (
  is       => 'rw',
  isa      => Bool,
  default  => 0,
  init_arg => undef,
);

has 'store_after_change' => (
  is      => 'rw',
  isa     => Bool,
  default => 0,
);

has 'file' => (
  is       => 'rw',
  isa      => Str,
  required => 1,
  trigger  => \&handle_change,
  default  => '/var/lib/buzzsaw/report.runlog.yaml',
);

has 'hourly' => (
  traits   => ['Hash'],
  is       => 'rw',
  isa      => HashRef[Int],
  default  => sub { {} },
  init_arg => undef,
  trigger  => \&handle_change,
  handles  => {
    has_hourly_timestamp => 'exists',
    get_hourly_timestamp => 'get',
    set_hourly_timestamp => 'set',
  },
);

has 'daily' => (
  traits   => ['Hash'],
  is       => 'rw',
  isa      => HashRef[Int],
  default  => sub { {} },
  init_arg => undef,
  trigger  => \&handle_change,
  handles  => {
    has_daily_timestamp => 'exists',
    get_daily_timestamp => 'get',
    set_daily_timestamp => 'set',
  },
);

has 'weekly' => (
  traits   => ['Hash'],
  is       => 'rw',
  isa      => HashRef[Int],
  default  => sub { {} },
  init_arg => undef,
  trigger  => \&handle_change,
  handles  => {
    has_weekly_timestamp => 'exists',
    get_weekly_timestamp => 'get',
    set_weekly_timestamp => 'set',
  },
);

has 'monthly' => (
  traits   => ['Hash'],
  is       => 'rw',
  isa      => HashRef[Int],
  default  => sub { {} },
  init_arg => undef,
  trigger  => \&handle_change,
  handles  => {
    has_monthly_timestamp => 'exists',
    get_monthly_timestamp => 'get',
    set_monthly_timestamp => 'set',
  },
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub handle_change {
  my ( $self, $new_value, $old_value ) = @_;

  if ( !$self->_initialising ) {
    $self->_changes(1);

    if ( $self->store_after_change ) {
      $self->store();
    }
  }

  return;
}

sub BUILD {
  my ($self) = @_;

  my $file = $self->file;

  if ( -f $file ) {

    my $data = eval { YAML::Syck::LoadFile( $file ) };

    if ( $@ || !defined $data || ref $data ne 'HASH' ) {
      die "Failed to load report log from '$file'\n";
    }

    for my $type (@REPORT_TYPES) {
      if ( exists $data->{$type} && defined $data->{$type} ) {
        $self->$type($data->{$type});
      }
    }

  }

  $self->_initialising(0);
  $self->_changes(0);

  return;
}

sub store {
  my ( $self, $force ) = @_;

  if ( !$self->_changes && !$force ) {
    return;
  }

  my %data;
  for my $type (@REPORT_TYPES) {
    my $logs = $self->$type;
    if ( scalar keys %{$logs} > 0 ) {
      $data{$type} = $logs;
    }
  }

  if ( scalar keys %data > 0 ) {

    my $file = $self->file;

    my ( $v, $dir, $filename ) = File::Spec->splitpath($file);
    my $tmpfh = File::Temp->new( TEMPLATE => 'tempXXXXX',
                                 DIR      => $dir,
                                 UNLINK   => 0 );
    my $tmpfile = $tmpfh->filename;

    {
      local $YAML::Syck::SortKeys = 1;

      YAML::Syck::DumpFile( $tmpfile, \%data );
    }

    my $updated = 0;
    if ( !-e $file ) {
      $updated = 1;
    } else {
      my $diff = Text::Diff::diff( $file, $tmpfile );
      $updated = length $diff > 0 ? 1 : 0;
    }

    if ($updated) {
      rename $tmpfile, $file
        or die "Could not rename '$tmpfile' to '$file': $!\n";
    }

  }

  $self->_changes(0);

  return;
}

sub DEMOLISH {
  my ($self) = @_;
  return $self->store();
}

1;
__END__

=head1 NAME

BuzzSaw::ReportLog - Tracks when BuzzSaw reports were last run.

=head1 VERSION

This documentation refers to BuzzSaw::ReportLog version 0.12.0

=head1 SYNOPSIS

use BuzzSaw::ReportLog;

my $log = BuzzSaw::ReportLog->new();

$log->set_hourly_timestamp( 'myreport' => time );

if ( $log->get_hourly_timestamp('myreport') ) {
  my $tstamp = $log->get_hourly_timestamp('myreport');
}

=head1 DESCRIPTION

This module provides a simple interface for storing timestamps
(seconds since the unix epoch) of BuzzSaw reports. The reports are
split into 4 categories - hourly, daily, weekly and monthly. It is
used by the C<BuzzSaw::Reporter> module to ensure reports are not run
more frequently than desired.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item hourly

This is a reference to a hash which is used to store the timestamps of
reports which are run hourly. It cannot be set as part of the call to
the C<new> method to create a new object.

=item daily

This is a reference to a hash which is used to store the timestamps of
reports which are run daily. It cannot be set as part of the call to
the C<new> method to create a new object.

=item weekly

This is a reference to a hash which is used to store the timestamps of
reports which are run weekly. It cannot be set as part of the call to
the C<new> method to create a new object.

=item monthly

This is a reference to a hash which is used to store the timestamps of
reports which are run monthly. It cannot be set as part of the call to
the C<new> method to create a new object.

=item store_after_change

This is a boolean which is used to control whether or not changes
should be immediately written back to the storage file. The default is
false. When it is false the changes will still be written back if an
explicit call is made to the C<store> method or when the object is
destroyed as it goes out of scope.

=item file

This is a string attribute which is used to specify the name of the
file into which the timestamps should be stored. The default is
C</var/lib/buzzsaw/report.runlog.yaml>.

=back

=head1 SUBROUTINES/METHODS

=over

=item new

Creates a new L<BuzzSaw::ReportLog> object. If the C<file> attribute
is specified and the file exists then an attempt will be made to load
the stored timestamp data using L<YAML::Syck>.

=item $log->has_hourly_timestamp($report_name)

Returns true or false to indicate whether (or not) a timestamp has
been recorded for an hourly report of this name.

=item $time = $log->get_hourly_timestamp($report_name)

Retrieves the timestamp, in seconds since the unix epoch, for an
hourly report of this name.

=item $log->set_hourly_timestamp($report_name => time )

Sets the timestamp, in seconds since the unix epoch, for an hourly
report of this name. If the C<store_after_change> attribute is set to
true then the change will immediately be written back to the log file.

=item $log->has_daily_timestamp($report_name)

Returns true or false to indicate whether (or not) a timestamp has
been recorded for an daily report of this name.

=item $time = $log->get_daily_timestamp($report_name)

Retrieves the timestamp, in seconds since the unix epoch, for a
daily report of this name.

=item $log->set_daily_timestamp($report_name => time )

Sets the timestamp, in seconds since the unix epoch, for a daily
report of this name. If the C<store_after_change> attribute is set to
true then the change will immediately be written back to the log file.

=item $log->has_weekly_timestamp($report_name)

Returns true or false to indicate whether (or not) a timestamp has
been recorded for a weekly report of this name.

=item $time = $log->get_weekly_timestamp($report_name)

Retrieves the timestamp, in seconds since the unix epoch, for a
weekly report of this name.

=item $log->set_weekly_timestamp($report_name => time )

Sets the timestamp, in seconds since the unix epoch, for a weekly
report of this name. If the C<store_after_change> attribute is set to
true then the change will immediately be written back to the log file.

=item $log->has_monthly_timestamp($report_name)

Returns true or false to indicate whether (or not) a timestamp has
been recorded for a monthly report of this name.

=item $time = $log->get_monthly_timestamp($report_name)

Retrieves the timestamp, in seconds since the unix epoch, for a
monthly report of this name.

=item $log->set_monthly_timestamp($report_name => time )

Sets the timestamp, in seconds since the unix epoch, for a monthly
report of this name. If the C<store_after_change> attribute is set to
true then the change will immediately be written back to the log file.

=item $log->store([$force])

This method can be called to write the log out to the file. It will
only do something if changes have been made to any of the timestamps
or if the optional C<force> parameter is set to true. If the newly
generated file is identical to the previous one then no replacement is
made so that file modification times are preserved.

=head1 DEPENDENCIES

This module is powered by L<Moose>. It uses L<YAML::Syck> to store the
log data into a file. It also uses L<Text::Diff> to check if the file
has changed so that it only has to overwrite when absolutely
necessary.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Reporter>, L<BuzzSaw::Report>

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

package BuzzSaw::Report;
use strict;
use warnings;

# $Id: Report.pm.in 23030 2013-04-05 12:33:25Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 23030 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Report.pm.in $
# $Date: 2013-04-05 13:33:25 +0100 (Fri, 05 Apr 2013) $

our $VERSION = '0.12.0';

use BuzzSaw::DB;
use BuzzSaw::DateTime;
use BuzzSaw::Types qw(BuzzSawDB BuzzSawDateTime BuzzSawTimeZone);

use MIME::Lite ();
use Template ();

use Moose;
use MooseX::Types::EmailAddress qw(EmailAddress EmailAddressList);
use MooseX::Types::Moose qw(ArrayRef Str);

has 'db' => (
  is       => 'rw',
  isa      => BuzzSawDB,
  coerce   => 1,
  required => 1,
  lazy     => 1,
  default  => sub { BuzzSaw::DB->new_with_config() },
);

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

has 'email_to' => (
  traits    => ['Array'],
  is        => 'ro',
  isa       => EmailAddressList,
  coerce    => 1,
  default   => sub { [] },
  handles   => {
    'send_by_email'      => 'count',
    'email_to_addresses' => 'elements',
  },
);

has 'email_from' => (
  is        => 'ro',
  isa       => EmailAddress,
  predicate => 'has_email_from',
);

has 'email_subject' => (
  is       => 'ro',
  isa      => Str,
  default  => sub { my $self = shift @_;
                    'BuzzSaw Report - ' . $self->name },
  required => 1,
  lazy     => 1,
);

has 'template' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  lazy     => 1,
  default  => sub {
    my $self = shift @_;
    my $template = lc($self->name) . '.tt';
    return $template;
  },
);

has 'tmpldirs' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayRef[Str],
    required => 1,
    default  => sub { [ '/usr/share/buzzsaw/templates/reports',
                        '/usr/share/buzzsaw/templates' ] },
    handles  => {
      add_tmpldir => 'unshift',
  },
);

has 'start' => (
    is       => 'ro',
    isa      => BuzzSawDateTime,
    required => 1,
    coerce   => 1,
    default  => sub { 'yesterday' },
);

has 'end' => (
    is       => 'ro',
    isa      => BuzzSawDateTime,
    required => 1,
    coerce   => 1,
    default  => sub { 'today' },
);

has 'order_by' => (
    is         => 'ro',
    isa        => 'ArrayRef|HashRef',
    required   => 1,
    default    => sub { ['logtime'] },
);

has 'timezone' => (
    is      => 'ro',
    isa     => BuzzSawTimeZone,
    coerce  => 1,
    default => sub { 'local' },
);

has 'program' => (
    is      => 'ro',
    isa     => Str,
    default => sub { my $self = shift;
                     return lc($self->name); },
);

has 'tags' => (
  traits    => ['Array'],
  is        => 'ro',
  isa       => ArrayRef[Str],
  lazy      => 1,
  default   => sub { [] },
  handles   => {
    has_tags  => 'count',
    tags_list => 'elements',
  },
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub BUILD {
    my ($self) = @_;

    my $diff = $self->end - $self->start;
    if ( $diff->is_negative ) {
        die "Error: Start date/time is later than end date/time\n"
    }
    return;
}

sub generate {
  my ($self) = @_;

  my @events = $self->find_events();

  my %results = $self->process_events(@events);

  my $text = $self->process_template( \%results, \@events );

  if ( $self->send_by_email ) {
    $self->send_email($text);
  } else {
    print $text;
  }

  return;
}

sub send_email {
  my ( $self, $text ) = @_;

  my ( $to, @cc ) = $self->email_to_addresses;

  my @args = (
    To       => $to,
    Subject  => $self->email_subject,
    Data     => $text,
  );

  # This is a slightly hacky attempt to avoid getting messages from
  # vacation auto-responders. The field name needs that trailing colon
  # as it is not in the list of "standard" headers supported by
  # MIME::Lite.

  push @args, ( 'Precedence:' => 'bulk' );

  if ( scalar @cc > 0 ) {
    my $cc = join q{, }, @cc;
    push @args, ( Cc => $cc );
  }

  if ( $self->has_email_from ) {
    push @args, ( From => $self->email_from );
  }

  my $msg = MIME::Lite->new(@args);

  my $send_ok = $msg->send();
  if ( !$send_ok ) {
    warn "Failed to send report email";
  }

  return;
}

sub process_template {
  my ( $self, $results, $events ) = @_;

  my $tt = Template->new(
    {
      INCLUDE_PATH => $self->tmpldirs,
    }
  ) or die "$Template::ERROR\n";

  my %vars = (
    results => $results,
    events  => $events,
    params  => {
      start => $self->start,
      end   => $self->end,
      tags  => $self->tags,
    },
  );

  my $output;
  $tt->process( $self->template, \%vars, \$output )
    or die $tt->error();

  return $output;
}

sub process_events {
  my ( $self, @events ) = @_;

  my %vars;


  return %vars;
}

sub find_events {
  my ($self) = @_;

  my $schema = $self->db->schema;
  my $events_rs = $schema->resultset('Event');

  # Find events within the required time range

  my $dtf = $schema->storage->datetime_parser;

  my %query = (
    logtime => [
      -and => { '>=', $dtf->format_datetime($self->start) },
              { '<=', $dtf->format_datetime($self->end)   },
    ],
  );

  # Add an extra computed column named "localtime" which holds the
  # localised version of the logtime. I tried applying the timezone
  # shift to the DateTime objects after creation but it was woefully
  # slow.

  # It is reasonably safe to embed the timezone name into some raw SQL
  # here since we have validated the timezone using the
  # BuzzSawTimeZone type.

  my $localtime = q{me.logtime at time zone '} . $self->timezone->name . q{' AS localtime};

  my %attrs = (
      '+select' => [ \$localtime ],
      '+as'     => [ 'localtime' ],
      join      => 'tags',
      order_by  => $self->order_by,
  );

  if ( $self->program =~ m/\S/ ) {
    $query{program} = $self->program;
  }

  if ( $self->has_tags ) {

    # join onto the tag table and search for events with the specified tags

    $query{'tags.name'} = { -in => $self->tags };
  } else {

      # prefetching does not entirely make sense when tags have been
      # specified. Need to think about how to rework the query so that
      # it is possible to limit the returned list of events to a set
      # of tags but then prefetch the complete set for each event.

      $attrs{prefetch} = 'tags';
  }

  my @events = $events_rs->search( \%query, \%attrs );

  return @events;
}

1;
__END__

=head1 NAME

BuzzSaw::Report - A Moose class which is used for generating BuzzSaw reports

=head1 VERSION

This documentation refers to BuzzSaw::Report version 0.12.0

=head1 SYNOPSIS

use BuzzSaw::Report;

my $report = BuzzSaw::Report->new(
                   email_to => 'fred@example.org',
                   template => 'myreport.tt',
                   tags     => 'kernel',
                   start    => 'yesterday',
                   end      => 'today',
);

$report->generate();

=head1 DESCRIPTION

This module provides the functionality to search the BuzzSaw database
for log events of interest and generate reports based on the
results. In simple situations it can be used directly, for more
complex searches or post-processing it can be sub-classed to allow the
overriding of specific methods.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item db

This is a reference to the L<BuzzSaw::DB> object which will be used to
find any events of interest.

It is possible to specify this as a string in which case that will be
considered to be a configuration file name and it will be handed off
to the C<new_with_config> method for the L<BuzzSaw::DB> class.

If you do not specify the L<BuzzSaw::DB> object then a new one will be
created by calling the C<new_with_config> method (which will use the
default configuration file name for that class).

=item name

This is the identifier for the report. The primary purpose of this
attribute is for use by the L<BuzzSaw::Reporter> module to track which
reports have been completed. The default is to use the final part of
the Perl module name (e.g. for C<BuzzSaw::Report::Kernel> the default
name is C<Kernel>). You are only likely to need to set this if you are
using the same Perl module to generate multiple different reports.

=item email_to

This attribute is used to hold the list of email addresses to which
the report should be delivered. If the list is empty then the report
will be printed to stdout instead. This attribute can be specified as
a simple string (which may contain multiple comma-separated addresses)
in which case it will be parsed and coerced into an array of separate
addresses. All email addresses specified MUST be valid according to
L<Email::Valid>.

=item email_from

This is a string attribute is used to set the email address from which
the report should be sent. If it is not set then the default chosen
will depend on the configuration of your system. If an email address
is specified it MUST be valid according to L<Email::Valid>.

=item email_subject

This is a string attribute which is used to set the subject when
sending the report by email. If it is not specified then the default
will be C<BuzzSaw Report -> concatenated with the name of the report.

=item template

This string attribute is the name of the template to be used to
generate the report. The Perl Template Toolkit is used to process the
files. Note that the file MUST exist within one of the directories
specified in the C<tmpldirs> attribute. If no file is specified then
the default is based on the lower-cased value of the name attribute
with a C<.tt> suffix appended.

=item tmpldirs

This list attribute is used to control the set of directories which
are searched for template files by the Template Toolkit. The default
list contains C</usr/share/buzzsaw/templates/reports> and
C</usr/share/buzzsaw/templates>.

=item start

This attribute is used to specify the start of the date/time range
within which to search for events of interest. It holds a
L<BuzzSaw::DateTime> object. It can be specified as a simple string in
which case it will be coerced into a new object. Supported strings
include: now, today, recent, yesterday, this-week, this-month,
this-year, week-ago, seconds from the unix epoch or variously
formatted date/time strings. See the module documentation for full
details.

=item end

This attribute is used to specify the end of the date/time range
within which to search for events of interest. It holds a
L<BuzzSaw::DateTime> object. It can be specified as a simple string in
which case it will be coerced into a new object. Supported strings
include: now, today, recent, yesterday, this-week, this-month,
this-year, week-ago, seconds from the unix epoch or variously
formatted date/time strings. See the module documentation for full
details.

=item timezone

This attribute is used to specify the timezone into which the event
timestamps (the C<logtime> field) should be converted. The default is
C<local> which relies on the L<DateTime> module working out what is
most suitable for your current time zone. All timestamps are stored in
the database in UTC, if you do not want any conversion then set this
attribute to C<UTC>. This attribute actually takes a
L<DateTime::TimeZone> object but a string will be converted
appropriately.

=item order_by

This attribute is used to control the order of the results from the
search for events of interest. It can be either a reference to an
array or a reference to a hash. For example:

        order_by => [qw/hostname logtime/]

        For explicit descending order:

         order_by => { -desc => [qw/col1 col2 col3/] }

        For explicit ascending order:

         order_by => { -asc => 'col' }

=item program

This is the name of the program field you wish to match in the log
messages. By default the value is the lower-cased version of the name
attribute for the report module instance (e.g. for
C<BuzzSaw::Report::Kernel> it is C<kernel>. If you wish to match all
log messages then set this to the empty string C<''>.

=item tags

This list attribute is used to specify which tags to search for in the
database when finding events of interest. If no tags are specified
then the search will return all events found within the specified
date/time range. The default is an empty list.

=back

=head1 SUBROUTINES/METHODS

=over

=item generate

=item @events = $report->find_events()

This method is used to construct the SQL query based on the date/time
range and the tags specified (if any). In a sub-class this method can
be overridden to do whatever is required to generate complex
queries. It must return an array of events (i.e. the result from
calling the L<DBIx::Class::ResultSet> search method in a list
context).

=item %results = $report->process_events(@events)

This method is used to do any post-processing of the events list which
is more easily done in Perl rather than within the database itself. By
default the method does nothing, override this in a sub-class if you
need to do complex classification of events. It must return a hash
which holds the results.

=item $text = $report->process_template( \%results, \@events )

This method uses the Perl Template Toolkit to generate the report
text. It is passed a reference to the hash of results from the
C<process_events> method and a reference to the original list of
events returned by the C<find_events> method.

The references to the results hash and events list are passed into the
template. Further to this a reference is passed in to a C<params> hash
which provides easy access to the values of the C<start>, C<end> and
C<tags> attributes.

The method returns the generated output as a simple text string.

=item send_email

If any email addresses have been specified via the C<email_to>
attribute then this method will be called to deliver the output via
email. The first address in the C<email_to> address will be set as the
C<To> field and any further addresses will be placed in the C<Cc>
field. The message is constructed and sent using the L<MIME::Lite>
module.

=item add_tmpldir

This can be used to add another directory to the list of those which
will be searched for templates when generating the report. Note that
the new directory is put onto the front of the list. This makes it
possible to override any standard template provided in the default
directories.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and also uses L<MooseX::Types> and
L<MooseX::Types::EmailAddress>. It uses the Perl Template Toolkit to
generate the reports. It uses L<MIME::Lite> to send reports via email.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::Report::Kernel>, L<BuzzSaw::DB>,
L<BuzzSaw::DateTime>, L<BuzzSaw::Types>.

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



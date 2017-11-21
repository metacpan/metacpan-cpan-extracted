package CPAN::Testers::Backend::ProcessReports;
our $VERSION = '0.003';
# ABSTRACT: Process an incoming test report into useful statistics

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <task> [--force | -f] [<reportid>...]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module is a L<Beam::Runnable> task that reads incoming test reports
#pod from testers and produces the basic stats needed for the common
#pod reporting on the website and via e-mail. This is the first step in
#pod processing test data: All other tasks require this step to be completed.
#pod
#pod =head1 ARGUMENTS
#pod
#pod =head2 reportid
#pod
#pod The IDs of reports to process. If specified, the report will be
#pod processed whether or not it was processed already (like C<--force>
#pod option).
#pod
#pod =head1 OPTIONS
#pod
#pod =head2 --force | -f
#pod
#pod Force re-processing of all reports. This will process all of the test
#pod reports again, so it may be prudent to limit to a set of test reports
#pod using the C<reportid> argument.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<CPAN::Testers::Backend>, L<CPAN::Testers::Schema>, L<Beam::Runnable>
#pod
#pod =cut

use v5.24;
use warnings;
use Moo;
use experimental 'signatures', 'postderef';
use Types::Standard qw( Str InstanceOf );
use Log::Any '$LOG';
with 'Beam::Runnable';
use JSON::MaybeXS qw( decode_json );
use Getopt::Long qw( GetOptionsFromArray );

#pod =attr schema
#pod
#pod A L<CPAN::Testers::Schema> object to access the database.
#pod
#pod =cut

has schema => (
    is => 'ro',
    isa => InstanceOf['CPAN::Testers::Schema'],
    required => 1,
);

#pod =attr metabase_dbh
#pod
#pod A L<DBI> object connected to the Metabase cache. This is a legacy database
#pod needed for some parts of the web app and backend. When these parts are
#pod updated to use the new test reports, we can remove this attribute.
#pod
#pod =cut

has metabase_dbh => (
    is => 'ro',
    isa => InstanceOf['DBI::db'],
    required => 1,
);

#pod =method run
#pod
#pod The main method that processes job arguments and performs the task.
#pod Called by L<Beam::Runner> or L<Beam::Minion>.
#pod
#pod =cut

sub run( $self, @args ) {
    GetOptionsFromArray(
        \@args, \my %opt,
        'force|f',
    );

    my @reports;
    if ( $opt{force} && !@args ) {
        $LOG->info( '--force and no IDs specified: Re-processing all reports' );
        @reports = $self->find_reports;
    }
    elsif ( @args ) {
        $LOG->info( 'Processing ' . @args . ' reports from command-line' );
        @reports = $self->find_reports( @args );
    }
    else {
        $LOG->info( 'Processing all unprocessed reports' );
        @reports = $self->find_unprocessed_reports;
        $LOG->info('Found ' . @reports . ' unprocessed report(s)');
    }

    my $stats = $self->schema->resultset('Stats');
    my $skipped = 0;

    for my $report (@reports) {
        local $@;
        my $stat;
        my $success = eval { $stat = $stats->insert_test_report($report); 1 };
        unless ($success) {
            my $guid = $report->id;
            $LOG->warn("Unable to process report GUID $guid. Skipping.");
            $LOG->debug("Error: $@");
            $skipped++;
            next;
        }
        $self->write_metabase_cache( $report, $stat );
    }

    $LOG->info("Skipped $skipped unprocessed report(s)") if $skipped;
}

#pod =method find_unprocessed_reports
#pod
#pod Returns a list of L<CPAN::Testers::Schema::Result::TestReport>
#pod objects for reports that are not in the cpanstats table.
#pod
#pod =cut

sub find_unprocessed_reports( $self ) {
    my $schema = $self->schema;
    my $stats = $schema->resultset('Stats');
    my $reports = $schema->resultset('TestReport')->search({
        id => {
            -not_in => $stats->get_column('guid')->as_query,
        },
        report => \[ "->> '\$.environment.language.name'=?", 'Perl 5' ],
    });
    return $reports->all;
}

#pod =method find_reports
#pod
#pod     @reports = $self->find_reports;
#pod     @reports = $self->find_reports( @ids );
#pod
#pod Find all the test reports to be processed by this module, optionally
#pod limited only to the IDs passed-in. Returns a list of
#pod L<CPAN::Testers::Schema::Result::TestReport> objects.
#pod
#pod =cut

sub find_reports( $self, @ids ) {
    my $reports = $self->schema->resultset( 'TestReport' )->search({
        report => \[ "->> '\$.environment.language.name'=?", 'Perl 5' ],
    });
    if ( @ids ) {
        $reports = $reports->search({
            id => {
                -in => \@ids,
            },
        });
    }
    return $reports->all;
}

#pod =method write_metabase_cache
#pod
#pod     $self->write_metabase_cache( $report_row, $stat_row );
#pod
#pod Write the report to the legacy metabase cache. This cache is used for
#pod some of the web apps and some of the backend processes. Until those
#pod processes are changed to use the new test report format, we need to
#pod maintain the old metabase cache.
#pod
#pod Once the legacy metabase cache is removed, this method can be removed
#pod
#pod =cut

sub write_metabase_cache( $self, $report_row, $stat_row ) {
    my $guid = $report_row->id;
    my $id = $stat_row->id;
    my $created_epoch = $report_row->created->epoch;
    my $report = $report_row->report;

    my $distname = $report->{distribution}{name};
    my $distversion = $report->{distribution}{version};

    my $upload_row = $self->schema->resultset( 'Upload' )->search({
        dist => $distname,
        version => $distversion,
    })->first;
    my $author = $upload_row->author;
    my $distfile = sprintf '%s/%s-%s.tar.gz', $author, $distname, $distversion;

    my %report = (
        grade => $report->{result}{grade},
        osname => $report->{environment}{system}{osname},
        osversion => $report->{environment}{system}{osversion},
        archname => $report->{environment}{language}{archname},
        perl_version => $report->{environment}{language}{version},
        textreport => (
            $report->{result}{output}{uncategorized} ||
            join "\n\n", grep defined, $report->{result}{output}->@{qw( configure build test install )},
        ),
    );

    # These imports are here so they can be easily removed later
    use Metabase::User::Profile;
    my %creator = (
        full_name => $report->{reporter}{name},
        email_address => $report->{reporter}{email},
    );
    my $creator;
    my ( $creator_row ) = $self->metabase_dbh->selectall_array(
        'SELECT * FROM testers_email WHERE email=?',
        { Slice => {} },
        $creator{email_address},
    );
    if ( !$creator_row ) {
        $creator = Metabase::User::Profile->create( %creator );
        $self->metabase_dbh->do(
            'INSERT INTO testers_email ( resource, fullname, email ) VALUES ( ?, ?, ? )',
            {},
            $creator->core_metadata->{resource},
            $creator{ full_name },
            $creator{ email_address },
        );
    }

    use CPAN::Testers::Report;
    my $metabase_report = CPAN::Testers::Report->open(
        resource => 'cpan:///distfile/' . $distfile,
        creator => $creator_row->{resource},
    );
    $metabase_report->add( 'CPAN::Testers::Fact::LegacyReport' => \%report);
    $metabase_report->add( 'CPAN::Testers::Fact::TestSummary' =>
        [$metabase_report->facts]->[0]->content_metadata()
    );
    $metabase_report->close();

    # Encode it to JSON
    my %facts;
    for my $fact ( $metabase_report->facts ) {
        my $name = ref $fact;
        $facts{ $name } = $fact->as_struct;
        $facts{ $name }{ content } = decode_json( $facts{ $name }{ content } );
    }

    # Serialize it to compress it using Data::FlexSerializer
    # "report" gets serialized with JSON
    use Data::FlexSerializer;
    my $json_zipper = Data::FlexSerializer->new(
        detect_compression  => 1,
        detect_json         => 1,
        output_format       => 'json'
    );
    my $report_zip = $json_zipper->serialize( \%facts );

    # "fact" gets serialized with Sereal
    my $sereal_zipper = Data::FlexSerializer->new(
        detect_compression  => 1,
        detect_sereal       => 1,
        output_format       => 'sereal'
    );
    my $fact_zip = $sereal_zipper->serialize( $metabase_report );

    $self->metabase_dbh->do(
        'REPLACE INTO metabase (guid,id,updated,report,fact) VALUES (?,?,?,?,?)',
        {},
        $guid, $id, $created_epoch, $report_zip, $fact_zip,
    );

    return;
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Backend::ProcessReports - Process an incoming test report into useful statistics

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    beam run <container> <task> [--force | -f] [<reportid>...]

=head1 DESCRIPTION

This module is a L<Beam::Runnable> task that reads incoming test reports
from testers and produces the basic stats needed for the common
reporting on the website and via e-mail. This is the first step in
processing test data: All other tasks require this step to be completed.

=head1 ATTRIBUTES

=head2 schema

A L<CPAN::Testers::Schema> object to access the database.

=head2 metabase_dbh

A L<DBI> object connected to the Metabase cache. This is a legacy database
needed for some parts of the web app and backend. When these parts are
updated to use the new test reports, we can remove this attribute.

=head1 METHODS

=head2 run

The main method that processes job arguments and performs the task.
Called by L<Beam::Runner> or L<Beam::Minion>.

=head2 find_unprocessed_reports

Returns a list of L<CPAN::Testers::Schema::Result::TestReport>
objects for reports that are not in the cpanstats table.

=head2 find_reports

    @reports = $self->find_reports;
    @reports = $self->find_reports( @ids );

Find all the test reports to be processed by this module, optionally
limited only to the IDs passed-in. Returns a list of
L<CPAN::Testers::Schema::Result::TestReport> objects.

=head2 write_metabase_cache

    $self->write_metabase_cache( $report_row, $stat_row );

Write the report to the legacy metabase cache. This cache is used for
some of the web apps and some of the backend processes. Until those
processes are changed to use the new test report format, we need to
maintain the old metabase cache.

Once the legacy metabase cache is removed, this method can be removed

=head1 ARGUMENTS

=head2 reportid

The IDs of reports to process. If specified, the report will be
processed whether or not it was processed already (like C<--force>
option).

=head1 OPTIONS

=head2 --force | -f

Force re-processing of all reports. This will process all of the test
reports again, so it may be prudent to limit to a set of test reports
using the C<reportid> argument.

=head1 SEE ALSO

L<CPAN::Testers::Backend>, L<CPAN::Testers::Schema>, L<Beam::Runnable>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

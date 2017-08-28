package CPAN::Testers::Backend::Migrate::MetabaseCache;
our $VERSION = '0.002';
# ABSTRACT: Migrate old metabase cache to new test report format

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <service> [--force | -f]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This task migrates the reports in the C<metabase.metabase> table to the
#pod C<cpanstats.test_report> table. This will enable us to drop the C<metabase>
#pod database altogether.
#pod
#pod =cut

use CPAN::Testers::Backend::Base 'Runnable';
with 'Beam::Runnable';
use Getopt::Long qw( GetOptionsFromArray );
use Data::FlexSerializer;
use JSON::MaybeXS qw( encode_json );
use CPAN::Testers::Report;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Fact::LegacyReport;


#pod =attr metabase_dbh
#pod
#pod The L<DBI> object connected to the C<metabase> database.
#pod
#pod =cut

has metabase_dbh => (
    is => 'ro',
    isa => InstanceOf['DBI::db'],
    required => 1,
);

#pod =attr schema
#pod
#pod The L<CPAN::Testers::Schema> to write reports to.
#pod
#pod =cut

has schema => (
    is => 'ro',
    isa => InstanceOf['CPAN::Testers::Schema'],
    required => 1,
);

sub run( $self, @args ) {
    GetOptionsFromArray(
        \@args, \my %opt,
        'force|f',
    );
    if ( $opt{force} && !@args ) {
        $LOG->info( '--force and no IDs specified: Re-processing all cache entries' );
        my $sth = $self->find_entries;
        $self->process_sth( $sth );
    }
    elsif ( @args ) {
        $LOG->info( 'Re-processing ' . @args . ' cache entries from command-line' );
        my $sth = $self->find_entries( @args );
        $self->process_sth( $sth );
    }
    else {
        $LOG->info( 'Processing all unprocessed cache entries' );
        my $sth = $self->find_unprocessed_entries;
        while ( my $count = $self->process_sth( $sth ) ) {
            $sth = $self->find_unprocessed_entries;
        }
    }
    return 0;
}

#pod =method process_sth
#pod
#pod Process the given statement handle full of reports. Returns the number
#pod of reports processed
#pod
#pod =cut

sub process_sth( $self, $sth ) {
    my $rs = $self->schema->resultset( 'TestReport' );
    my $count = 0;
    my %ids;
    while ( my $row = $sth->fetchrow_hashref ) {
        next if $ids{ $row->{guid} }++;
        my $fact = $self->parse_metabase_report( $row );
        $rs->insert_metabase_fact( $fact );
        $count++;
    }
    return $count;
}

#pod =method find_unprocessed_entries
#pod
#pod     @rows = $self->find_unprocessed_rows;
#pod
#pod Returns a L<DBI> statement handle on to a list of C<metabase.metabase>
#pod row hashrefs for reports that are not in the main test report table
#pod (managed by L<CPAN::Testers::Schema::Result::TestReport>).
#pod
#pod =cut

sub find_unprocessed_entries( $self ) {
    my $sth = $self->metabase_dbh->prepare(
        "SELECT * FROM metabase WHERE guid NOT IN ( SELECT id FROM cpanstats.test_report ) LIMIT 10000",
    );
    $sth->execute;
    return $sth;
}

#pod =method find_entries
#pod
#pod     @entries = $self->find_entries;
#pod     @entries = $self->find_entries( @ids );
#pod
#pod Find all the cache entries to be processed by this module, optionally
#pod limited only to the IDs passed-in. Returns a list of row hashrefs.
#pod
#pod =cut

sub find_entries( $self, @ids ) {
    my ( $where, @values );
    if ( @ids ) {
        $where = " WHERE guid IN (" . join( ', ', ( '?' x @ids ) ) . ")";
        @values = @ids;
    }
    my $sth = $self->metabase_dbh->prepare(
        "SELECT * FROM metabase" . $where
    );
    $sth->execute( @values );
    return $sth;
}

#pod =method parse_metabase_report
#pod
#pod This sub undoes the processing that CPAN Testers expects before it is
#pod put in the database so we can ensure that the report was submitted
#pod correctly.
#pod
#pod This code is stolen from CPAN::Testers::Data::Generator sub load_fact
#pod
#pod =cut

my $zipper = Data::FlexSerializer->new(
    detect_compression  => 1,
    detect_sereal       => 1,
    detect_json         => 1,
);

sub parse_metabase_report( $self, $row ) {
    if ( $row->{fact} ) {
        return $zipper->deserialize( $row->{fact} );
    }

    my $data = $zipper->deserialize( $row->{report} );
    my $struct = {
        metadata => {
            core => {
                $data->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}->%*,
                guid => $row->{guid},
                type => 'CPAN-Testers-Report',
            },
        },
        content => encode_json( [
            $data->{'CPAN::Testers::Fact::LegacyReport'},
            $data->{'CPAN::Testers::Fact::TestSummary'},
        ] ),
    };
    #; use Data::Dumper;
    #; warn Dumper $struct;
    my $fact = CPAN::Testers::Report->from_struct( $struct );
    return $fact;
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Backend::Migrate::MetabaseCache - Migrate old metabase cache to new test report format

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    beam run <container> <service> [--force | -f]

=head1 DESCRIPTION

This task migrates the reports in the C<metabase.metabase> table to the
C<cpanstats.test_report> table. This will enable us to drop the C<metabase>
database altogether.

=head1 ATTRIBUTES

=head2 metabase_dbh

The L<DBI> object connected to the C<metabase> database.

=head2 schema

The L<CPAN::Testers::Schema> to write reports to.

=head1 METHODS

=head2 process_sth

Process the given statement handle full of reports. Returns the number
of reports processed

=head2 find_unprocessed_entries

    @rows = $self->find_unprocessed_rows;

Returns a L<DBI> statement handle on to a list of C<metabase.metabase>
row hashrefs for reports that are not in the main test report table
(managed by L<CPAN::Testers::Schema::Result::TestReport>).

=head2 find_entries

    @entries = $self->find_entries;
    @entries = $self->find_entries( @ids );

Find all the cache entries to be processed by this module, optionally
limited only to the IDs passed-in. Returns a list of row hashrefs.

=head2 parse_metabase_report

This sub undoes the processing that CPAN Testers expects before it is
put in the database so we can ensure that the report was submitted
correctly.

This code is stolen from CPAN::Testers::Data::Generator sub load_fact

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

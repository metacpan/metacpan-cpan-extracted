
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::ResultSet::TestReport> module which
queries for L<CPAN::Testers::Schema::Result::TestReport> objects.

=head1 SEE ALSO

L<DBIx::Class::ResultSet>

=cut

use CPAN::Testers::Schema::Base 'Test';
use Metabase::Fact;
use Test::Reporter;
use CPAN::Testers::Report;
use CPAN::Testers::Fact::LegacyReport;
use CPAN::Testers::Fact::TestSummary;
use JSON::MaybeXS;

my $schema = prepare_temp_schema;
my $user_resource = 'metabase:user:12345678-1234-1234-1234-123456789012';
$schema->resultset( 'MetabaseUser' )->create({
    resource => $user_resource,
    fullname => 'Doug Bell',
    email => 'doug@preaction.me',
});

subtest 'insert_metabase_fact' => sub {
    my $given_report = create_report(
        grade => 'pass',
        distfile => 'PREACTION/Foo-Bar-1.24.tar.gz',
        distribution => 'Foo-Bar-1.24',
        textreport => 'Test output',
        creator => $user_resource,
    );
    my $expect_report = {
        reporter => {
            name => 'Doug Bell',
            email => 'doug@preaction.me',
        },
        environment => {
            system => {
                osname => 'linux',
                osversion => '2.14.4',
            },
            language => {
                name => 'Perl 5',
                archname => 'x86_64-linux',
                version => '5.12.0',
            },
        },
        distribution => {
            name => 'Foo-Bar',
            version => '1.24',
        },
        result => {
            grade => 'pass',
            output => {
                uncategorized => 'Test output',
            },
        },
    };
    my $row = $schema->resultset( 'TestReport' )->insert_metabase_fact( $given_report );

    my $got_report = $row->report;
    my $id = delete $got_report->{id};
    is $id, $given_report->core_metadata->{guid}, 'id is correct';

    my $created = delete $got_report->{created};
    is $created, $given_report->core_metadata->{creation_time};

    isa_ok $row->created, 'DateTime';
    is $row->created . 'Z', $given_report->core_metadata->{creation_time};

    is_deeply $got_report, $expect_report, 'Metabase::Fact is converted correctly';
};

done_testing;

#sub create_report
#
#   my $report = create_report(
#       grade => 'pass',
#       distfile => 'P/PR/PREACTION/Foo-Bar-1.24.tar.gz',
#       distribution => 'Foo-Bar-1.24',
#       textreport => 'Test output',
#       creator => 'metabase:user:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX',
#   );
#
# Create a new report to submit. Returns a data structure suitable to be
# encoded into JSON and submitted.
#
# This code is stolen from:
#   * Test::Reporter::Transport::Metabase sub send
#   * Metabase::Client::Simple sub submit_fact

sub create_report( %attrs ) {
    my $user = delete $attrs{creator};
    my $text = delete $attrs{textreport};
    my $report = Test::Reporter->new( transport => 'Null', %attrs );

    # Build CPAN::Testers::Report with its various component facts.
    my $metabase_report = CPAN::Testers::Report->open(
        resource => 'cpan:///distfile/' . $report->distfile,
        creator => $user,
    );

    $metabase_report->add( 'CPAN::Testers::Fact::LegacyReport' => {
        grade => $report->grade,
        osname => 'linux',
        osversion => '2.14.4',
        archname => 'x86_64-linux',
        perl_version => '5.12.0',
        textreport => $text,
    });

    # TestSummary happens to be the same as content metadata 
    # of LegacyReport for now
    $metabase_report->add( 'CPAN::Testers::Fact::TestSummary' =>
        [$metabase_report->facts]->[0]->content_metadata()
    );

    $metabase_report->close();

    return $metabase_report;
}

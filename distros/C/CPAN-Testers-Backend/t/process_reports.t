
=head1 DESCRIPTION

This test ensures that raw test reports from the C<test_reports> table
are processed into summary rows in the C<cpanstats> table. We also test
that some backwards-compatibility layers are kept, like updating the old
local C<metabase> cache.

=head1 SEE ALSO

L<CPAN::Testers::Backend::ProcessReports>

=cut

use Log::Any::Test;
use Log::Any '$LOG';

use CPAN::Testers::Backend::Base 'Test';
use Mock::MonkeyPatch;
use CPAN::Testers::Schema;
use CPAN::Testers::Backend::ProcessReports;
eval { require Test::mysqld } or plan skip_all => 'Requires Test::mysqld';

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    },
) or plan skip_all => $Test::mysqld::errstr;

my $class = 'CPAN::Testers::Backend::ProcessReports';
my $schema = CPAN::Testers::Schema->connect(
    $mysqld->dsn(dbname => 'test'),
    undef, undef,
    { ignore_version => 1 },
);
$schema->deploy;
$schema->storage->dbh->do(q{
CREATE TABLE `page_requests` (
  `type` varchar(8) NOT NULL,
  `name` varchar(255) NOT NULL,
  `weight` int(2) unsigned NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `id` int(10) unsigned DEFAULT '0'
)});

use DBI;
my $metabase_dbh = DBI->connect( 'dbi:SQLite::memory:', undef, undef, { RaiseError => 1 } );
$metabase_dbh->do(q{
    CREATE TABLE `metabase` (
        `guid` CHAR(36) NOT NULL PRIMARY KEY,
        `id` INT(10) NOT NULL,
        `updated` VARCHAR(32) DEFAULT NULL,
        `report` BINARY NOT NULL,
        `fact` BINARY
    )
});
$metabase_dbh->do(q{
    CREATE TABLE `testers_email` (
        `id` INTEGER PRIMARY KEY,
        `resource` VARCHAR(64) NOT NULL,
        `fullname` VARCHAR(255) NOT NULL,
        `email` VARCHAR(255) DEFAULT NULL
    )
});

my $pr = $class->new(
    schema => $schema,
    from => 'demo@test.com',
    metabase_dbh => $metabase_dbh,
);

$schema->resultset('Upload')->create({
    uploadid => 169497,
    type => 'cpan',
    author => 'YUKI',
    dist => 'Sorauta-SVN-AutoCommit',
    version => 0.02,
    filename => 'Sorauta-SVN-AutoCommit-0.02.tar.gz',
    released => 1327657454,
});

$schema->resultset('Stats')->create({
    id => 82067962,
    guid => 'd0ab4d36-3343-11e7-b830-917e22bfee97',
    state => 'fail',
    postdate => 201705,
    tester => 'andreas.koenig.gmwojprw@franz.ak.mind.de ((Andreas J. Koenig))',
    dist => 'Sorauta-SVN-AutoCommit',
    version => '0.02',
    platform => 'x86_64-linux',
    perl => '5.22.2',
    osname => 'linux',
    osvers => '4.8.0-2-amd64',
    fulldate => 201705071640,
    type => 2,
    uploadid => 169497,
});

my @reports;
push @reports, $schema->resultset('TestReport')->create({
    id => 'd0ab4d36-3343-11e7-b830-917e22bfee97',
    report => {
        reporter => {
            name  => 'Andreas J. Koenig',
            email => 'andreas.koenig.gmwojprw@franz.ak.mind.de',
        },
        environment => {
            system => {
                osname => 'linux',
                osversion => '4.8.0-2-amd64',
            },
            language => {
                name => 'Perl 5',
                version => '5.22.2',
                archname => 'x86_64-linux',
            },
        },
        distribution => {
            name => 'Sorauta-SVN-AutoCommit',
            version => '0.02',
        },
        result => {
            grade => 'FAIL',
            output => {
                uncategorized => 'Test report',
            },
        },
    },
});

push @reports, $schema->resultset('TestReport')->create({
    id => 'cfa81824-3343-11e7-b830-917e22bfee97',
    report => {
        reporter => {
            name  => 'Andreas J. Koenig',
            email => 'andreas.koenig.gmwojprw@franz.ak.mind.de',
        },
        environment => {
            system => {
                osname => 'linux',
                osversion => '4.8.0-2-amd64',
            },
            language => {
                name => 'Perl 5',
                version => '5.20.1',
                archname => 'x86_64-linux-thread-multi',
            },
        },
        distribution => {
            name => 'Sorauta-SVN-AutoCommit',
            version => '0.02',
        },
        result => {
            grade => 'FAIL',
            output => {
                uncategorized => 'Test report',
            },
        },
    },
});

# This process must not handle Perl 6 reports
$schema->resultset('TestReport')->create({
    id => 'f0ab4d36-3343-11e7-b830-917e22bfee98',
    report => {
        reporter => {
            name  => 'Zoffix Znet',
            email => 'zoffix@example.com',
        },
        environment => {
            system => {
                osname => 'linux',
                osversion => '4.8.0-2-amd64',
            },
            language => {
                name => 'Perl 6',
                version => 'v6.c',
                archname => 'x86_64-linux',
            },
        },
        distribution => {
            name => 'Foo-Bar',
            version => '0.01',
        },
        result => {
            grade => 'PASS',
            output => {
                uncategorized => 'Test report',
            },
        },
    },
});

subtest find_unprocessed_reports => sub {
    my @to_process = $pr->find_unprocessed_reports;
    is @to_process, 1, 'one unprocessed result';
    is $to_process[0]->id, 'cfa81824-3343-11e7-b830-917e22bfee97', 'correct id to be processed';
};

subtest run => sub {
    subtest 'check that the initial scenario is valid' => sub {
        my $reports = $schema->resultset('TestReport')->count;
        my $stats   = $schema->resultset('Stats')->count;
        isnt $reports, $stats, 'test that stats and test reports are unequal in count';
        my @to_process = $pr->find_unprocessed_reports;
        isnt @to_process, 0, 'some reports are not processed';
    };

    subtest 'the lack of an upload causes a test report to skip migration' => sub {
        $LOG->clear;
        my $mock = Mock::MonkeyPatch->patch(
            'CPAN::Testers::Schema::ResultSet::Stats::insert_test_report',
            sub { die "Oops" },
        );
        $pr->run;

        subtest 'check that the skip works' => sub {
            $LOG->contains_ok(qr'found 1'i, 'found message was logged');
            $LOG->contains_ok(qr'skipping'i, 'individual skip message was logged');
            $LOG->contains_ok(qr'skipped 1'i, 'skipped message was logged');
            my $reports = $schema->resultset('TestReport')->count;
            my $stats   = $schema->resultset('Stats')->count;
            isnt $reports, $stats+1, 'test that stats and test reports are unequal in count';
            my @to_process = $pr->find_unprocessed_reports;
            isnt @to_process, 0, 'some reports are not processed';
        };
    };

    # now that we allow success
    $LOG->clear;
    $pr->run;

    subtest 'check that the final scenario is correct' => sub {
        $LOG->contains_ok(qr'found 1'i, 'found message was logged');
        $LOG->does_not_contain_ok(qr'skip'i, 'no skip message was logged');
        $LOG->does_not_contain_ok(qr'error'i, 'no error message logged');
        my $reports = $schema->resultset('TestReport')->count;
        my $stats   = $schema->resultset('Stats')->count;
        is $reports, $stats+1, 'test that stats and tests are now equal in count';
        my @to_process = $pr->find_unprocessed_reports;
        is @to_process, 0, 'no reports remain to be processed';

        my ( $cache_row ) = $metabase_dbh->selectall_array(
            'SELECT * FROM metabase', { Slice => {} },
        );
        ok $cache_row, 'cache row exists';
        my $cache = parse_metabase_report( $cache_row );
        isa_ok $cache->{fact}, 'CPAN::Testers::Report';
        is_deeply $cache->{report}{'CPAN::Testers::Fact::LegacyReport'}{content},
            {
                archname => 'x86_64-linux-thread-multi',
                grade => 'FAIL',
                osname => 'linux',
                osversion => '4.8.0-2-amd64',
                perl_version => '5.20.1',
                textreport => 'Test report',
            },
            'report is correct'
                or diag explain $cache->{report}{'CPAN::Testers::Fact::LegacyReport'}{content};

        my ( $tester_row ) = $metabase_dbh->selectall_array(
            'SELECT * FROM testers_email', { Slice => {} },
        );
        is $tester_row->{fullname}, 'Andreas J. Koenig', 'tester name is correct';
        is $tester_row->{email}, 'andreas.koenig.gmwojprw@franz.ak.mind.de', 'tester email is correct';

        my @page_requests = $schema->storage->dbh->selectall_array(
            'SELECT type, name, weight, id FROM page_requests', { Slice => {} },
        );
        is_deeply \@page_requests,
            [
                { type => 'author', name => 'YUKI', weight => 1, id => $cache_row->{id} },
                { type => 'distro', name => 'Sorauta-SVN-AutoCommit', weight => 1, id => $cache_row->{id} },
            ],
            'page_requests are correct';
    };

    subtest 'process a single report' => sub {
        $LOG->clear;
        $reports[0]->report->{result}{grade} = 'PASS';
        $reports[0]->update({ report => $reports[0]->report });

        $pr->run( $reports[0]->id );

        $LOG->contains_ok(qr'Processing 1 reports'i, 'found message was logged');

        my $stat = $schema->resultset( 'Stats' )->search({ guid => $reports[0]->id })->first;
        is $stat->state, 'pass', 'stat grade is updated';
    };

    subtest 'reprocess all reports' => sub {
        $LOG->clear;
        $reports[0]->report->{result}{grade} = 'UNKNOWN';
        $reports[0]->update({ report => $reports[0]->report });
        $reports[1]->report->{result}{grade} = 'UNKNOWN';
        $reports[1]->update({ report => $reports[1]->report });

        $pr->run( '--force' );

        $LOG->contains_ok(qr're-processing all reports'i, 'found message was logged');

        my $stat = $schema->resultset( 'Stats' )->search({ guid => $reports[0]->id })->first;
        is $stat->state, 'unknown', 'stat grade is updated (0)';
        $stat = $schema->resultset( 'Stats' )->search({ guid => $reports[1]->id })->first;
        is $stat->state, 'unknown', 'stat grade is updated (1)';
    };
};

done_testing;

#sub parse_metabase_report
#
# This sub undoes the processing that CPAN Testers expects before it is
# put in the database so we can ensure that the report was submitted
# correctly.
#
# This code is stolen from:
#   * CPAN::Testers::Data::Generator sub load_fact
#
# Once the legacy metabase cache is removed, this sub can be removed
sub parse_metabase_report {
    my ( $row ) = @_;
    my %report;

    my $sereal_zipper = Data::FlexSerializer->new(
        detect_compression  => 1,
        detect_sereal       => 1,
        detect_json         => 1,
    );
    $report{ fact } = $sereal_zipper->deserialize( $row->{fact} );

    my $json_zipper = Data::FlexSerializer->new(
        detect_compression  => 1,
        detect_json         => 1,
        detect_sereal       => 1,
    );
    $report{ report } = $json_zipper->deserialize( $row->{report} );

    return \%report;
}



=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::ResultSet::Stats> module which
queries for L<CPAN::Testers::Schema::Result::Stats> objects.

=head1 SEE ALSO

L<DBIx::Class::ResultSet>

=cut

use CPAN::Testers::Schema::Base 'Test';
use CPAN::Testers::Schema;

use Scalar::Util 'looks_like_number';

my $schema = CPAN::Testers::Schema->connect( 'dbi:SQLite::memory:', undef, undef, { ignore_version => 1 } );
$schema->deploy;
my $rs = $schema->resultset('Stats');

subtest 'insert_test_report' => sub {
    my $report = $schema->resultset('TestReport')->create({
        id => 'd0ab4d36-3343-11e7-b830-917e22bfee97',
        created => DateTime->new(
            year => 2017,
            month => 05,
            day => 07,
            hour => 16,
            minute => 40,
        ),
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
            },
        },
    });

    subtest 'upload does not exist' => sub {
        my $stat = eval { $rs->insert_test_report($report) };
        my $err = $@;
        ok !$stat, 'stat record was not created';
        like $err, qr'No upload matches for dist Sorauta-SVN-AutoCommit version 0.02 \(report d0ab4d36-3343-11e7-b830-917e22bfee97\)', 'correct error';
    };

    my $upload = $schema->resultset('Upload')->create({
        uploadid => 169497,
        type => 'cpan',
        author => 'YUKI',
        dist => 'Sorauta-SVN-AutoCommit',
        version => 0.02,
        filename => 'Sorauta-SVN-AutoCommit-0.02.tar.gz',
        released => 1327657454,
    });

    my $stat_id;
    subtest 'upload exists' => sub {
        my $stat = $rs->insert_test_report($report);
        $stat_id = $stat->id;

        isa_ok $stat, 'CPAN::Testers::Schema::Result::Stats';
        ok looks_like_number($stat->id), 'an id was generated';
        is $stat->guid, 'd0ab4d36-3343-11e7-b830-917e22bfee97', 'correct guid';
        is $stat->state, 'fail', 'correct test state';
        is $stat->postdate, 201705, 'correct postdate';
        is $stat->tester, '"Andreas J. Koenig" <andreas.koenig.gmwojprw@franz.ak.mind.de>', 'correct tester';
        is $stat->dist, 'Sorauta-SVN-AutoCommit', 'correct dist';
        is $stat->version, '0.02', 'correct version';
        is $stat->platform, 'x86_64-linux', 'correct platform';
        is $stat->perl, '5.22.2', 'correct perl';
        is $stat->osname, 'linux', 'correct osname';
        is $stat->osvers, '4.8.0-2-amd64', 'correct osvers';
        is $stat->fulldate, 201705071640, 'correct fulldate';
        is $stat->type, 2, 'correct type';
        is $stat->uploadid, 169497, 'correct uploadid';
    };

    subtest 'reprocess report' => sub {
        $report->report->{result}{grade} = 'PASS';
        $report->update({ report => $report->report });
        my $stat = $rs->insert_test_report( $report );
        is $stat->id, $stat_id, 'stat is updated, not duplicated';
        is $stat->guid, 'd0ab4d36-3343-11e7-b830-917e22bfee97', 'correct guid';
        is $stat->state, 'pass', 'correctly changed test state';
    };
};

done_testing;




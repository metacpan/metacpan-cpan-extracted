
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::Upload> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';
use List::Util qw( sum );

subtest 'create' => sub {
    my $schema = prepare_temp_schema;
    my %upload = (
        type => 'cpan',
        dist => 'My-Dist',
        version => '1.000',
        author => 'PREACTION',
        filename => 'My-Dist-1.000.tar.gz',
        released => 1366237867, # Wed Apr 17 22:31:07 2013
    );
    my $upload = $schema->resultset( 'Upload' )->create( \%upload );
    ok $upload, 'row is created';
    ok $upload->uploadid, 'uploadid is created';

    isa_ok $upload->released, 'DateTime', 'released column is auto-inflated to DateTime object';
    is $upload->released->epoch, $upload{ released }, 'datetime is correct';
    is $upload->released . "", "2013-04-17T22:31:07Z", 'time zone is set correctly';
};

subtest 'report_metrics' => sub {
    my $schema = prepare_temp_schema;
    my %upload = (
        type => 'cpan',
        dist => 'My-Dist',
        version => '1.000',
        author => 'PREACTION',
        filename => 'My-Dist-1.000.tar.gz',
        released => 1366237867, # Wed Apr 17 22:31:07 2013
    );
    my $upload = $schema->resultset( 'Upload' )->create( \%upload );

    my $perl = $schema->resultset( 'PerlVersion' )->find_or_create({
        version => '5.22.0',
    });

    my $report = $schema->resultset( 'TestReport' )->create({
        id => '12345678-1234-1234-1234-123456789012',
    });
    my $summary = $schema->resultset( 'Stats' )->create({
        guid => $report->id,
        state => 'fail',
        tester => 'doug@example.com (Doug Bell)',
        postdate => '201608',
        %upload{qw( dist version )},
        uploadid => $upload->uploadid,
        platform => 'darwin-2level',
        perl => $perl->version,
        osname => 'darwin',
        osvers => '10.8.0',
        fulldate => '201608120401',
        type => 2,
    });

    my %metric_common = (
        %upload{qw( dist version )},
        id => $summary->id,
        guid => $summary->guid,
        uploadid => $upload->uploadid,
        oncpan => 1,
        distmat => 1,
        perlmat => 1,
        patched => 1,
        pass => 0,
        fail => 0,
        na => 0,
        unknown => 0,
    );

    my @metric_rows = (
        {
            %metric_common,
            pass => 1,
        },
        {
            %metric_common,
            perlmat => 2,
            fail => 1,
        },
        {
            %metric_common,
            patched => 2,
            na => 1,
        },
    );
    $schema->resultset( 'Release' )->create( $_ ) for @metric_rows;


    my ( @metrics, $rs );
    $rs = $upload->report_metrics->search({ perlmat => 1, patched => 1 });
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    @metrics = $rs->all;
    is_deeply \@metrics, [ $metric_rows[0] ], 'standard release perl';

    $rs = $upload->report_metrics->search({ perlmat => 2, patched => 1 });
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    @metrics = $rs->all;
    is_deeply \@metrics, [ $metric_rows[1] ], 'standard dev perl';

    $rs = $upload->report_metrics->search({ perlmat => 1, patched => 2 });
    $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
    @metrics = $rs->all;
    is_deeply \@metrics, [ $metric_rows[2] ], 'patched release perl';

    subtest 'total related report_metrics' => sub {
        $rs = $schema->resultset( 'Upload' )->related_resultset( 'report_metrics' )->total_by_release;
        $rs->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );
        @metrics = $rs->all;
        is_deeply \@metrics,
            [
                {
                    $metric_rows[0]->%{qw( dist version uploadid pass unknown )},
                    $metric_rows[1]->%{ 'fail' },
                    $metric_rows[2]->%{ 'na' },
                    total => sum(
                        $metric_rows[0]->@{qw( pass unknown )},
                        $metric_rows[1]{fail},
                        $metric_rows[2]{na},
                    ),
                },
            ],
            'totalling related_resultset works';
    };
};

done_testing;

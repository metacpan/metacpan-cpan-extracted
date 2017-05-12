
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::Release> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';

subtest 'upload relationship' => sub {
    my $schema = prepare_temp_schema;
    my %upload = (
        type => 'cpan',
        dist => 'My-Dist',
        version => '1.000',
        author => 'PREACTION',
        filename => 'My-Dist-1.000.tar.gz',
        released => 1366237867,
    );
    my $upload = $schema->resultset( 'Upload' )->create( \%upload );

    my %release = (
        dist => 'My-Dist',
        version => '1.000',
        id => 1,
        guid => '00000000-0000-0000-0000-000000000000',
        oncpan => 1,
        distmat => 1,
        perlmat => 1,
        patched => 1,
        pass => 35,
        fail => 1,
        na => 0,
        unknown => 0,
        uploadid => $upload->uploadid,
    );
    my $release = $schema->resultset( 'Release' )->create( \%release );

    ok $release->upload, 'upload relationship exists';
    is $release->upload->uploadid, $upload->uploadid, 'correct upload is related';
};

subtest 'stats relationship' => sub {
    my $schema = prepare_temp_schema;
    my %report = (
        dist => 'My-Dist',
        version => '1.000',
        uploadid => 1,
        id => 1,
        guid => '00000000-0000-0000-0000-000000000001',
        state => 'pass',
        postdate => '201608',
        fulldate => '201608120401',
        tester => 'doug@example.com (Doug Bell)',
        platform => 'darwin-2level',
        perl => '5.22.0',
        osname => 'darwin',
        osvers => '10.8.0',
        type => 2,
    );
    my $report = $schema->resultset( 'Stats' )->create( \%report );

    my %release = (
        dist => 'My-Dist',
        version => '1.000',
        id => $report->id,
        guid => $report->guid,
        oncpan => 1,
        distmat => 1,
        perlmat => 1,
        patched => 1,
        pass => 35,
        fail => 1,
        na => 0,
        unknown => 0,
        uploadid => 1,
    );
    my $release = $schema->resultset( 'Release' )->create( \%release );

    ok $release->report, 'report relationship exists';
    is $release->report->guid, $report->guid, 'correct report is related';
};

done_testing;

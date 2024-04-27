
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::Stats> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';

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
my $version_row = $schema->resultset( 'PerlVersion' )->create({ version => '5.24.0' });

subtest 'reader methods' => sub {
    my %stats = (
        type => 2,
        guid => '00000000-0000-0000-0000-000000000001',
        state => 'pass',
        postdate => '201607',
        tester => 'doug@example.com (Doug Bell)',
        dist => 'My-Dist',
        version => '1.000',
        platform => 'darwin-2level',
        perl => '5.24.0',
        osname => 'darwin',
        osvers => '15.5.0',
        fulldate => '201607141234',
        uploadid => $upload->uploadid,
    );
    my $row = $schema->resultset( 'Stats' )->create( \%stats );
    is $row->dist_name, 'My-Dist', 'dist_name is correct';
    is $row->dist_version, '1.000', 'dist_version is correct';
    is $row->lang_version, 'Perl 5 v5.24.0', 'lang_version is correct';
    is $row->platform, 'darwin-2level', 'platform is correct';
    is $row->grade, 'pass', 'grade is correct';
    is $row->tester_name, "Doug Bell", 'tester_name is correct';
    isa_ok $row->datetime, 'DateTime';
    is $row->datetime->datetime, '2016-07-14T12:34:00';
};

subtest 'relationships' => sub {
    my %stats = (
        type => 2,
        guid => '00000000-0000-0000-0000-000000000002',
        state => 'pass',
        postdate => '201607',
        tester => 'doug@example.com (Doug Bell)',
        dist => 'My-Dist',
        version => '1.000',
        platform => 'darwin-2level',
        perl => '5.24.0',
        osname => 'darwin',
        osvers => '15.5.0',
        fulldate => '201607141234',
        uploadid => $upload->uploadid,
    );
    my $stats = $schema->resultset( 'Stats' )->create( \%stats );

    ok $stats->upload, 'upload relationship exists';
    is $stats->upload->uploadid, $upload->uploadid, 'correct upload is related';

    ok $stats->perl_version, 'perl_version relationship exists';
    is $stats->perl_version->perl, '5.24.0', 'correct perl version is related';
};

done_testing;

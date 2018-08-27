
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

subtest 'upload relationship' => sub {
    my %stats = (
        type => 2,
        guid => '00000000-0000-0000-0000-000000000000',
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
};

subtest 'perl_version relationship' => sub {
    my $schema = prepare_temp_schema;
    my $version_row = $schema->resultset( 'PerlVersion' )->create({ version => '5.24.0' });

    my %stats = (
        type => 2,
        guid => '00000000-0000-0000-0000-000000000000',
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

    ok $stats->perl_version, 'perl_version relationship exists';
    is $stats->perl_version->perl, '5.24.0', 'correct perl version is related';

};

done_testing;

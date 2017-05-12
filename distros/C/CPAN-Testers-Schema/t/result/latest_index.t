
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::LatestIndex> class.

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

    my %latest = (
        oncpan => 1,
        dist => 'My-Dist',
        version => '1.000',
        author => 'PREACTION',
        released => 1366237867,
        uploadid => $upload->uploadid,
    );
    my $latest = $schema->resultset( 'LatestIndex' )->create( \%latest );

    ok $latest->upload, 'upload relationship exists';
    is $latest->upload->uploadid, $upload->uploadid, 'correct upload is related';
};

done_testing;


=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::TestReport> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';
use Scalar::Util qw( looks_like_number );
my $schema = prepare_temp_schema;
my $HEX = qr{[A-Fa-f0-9]};

subtest 'column defaults' => sub {
    my $row = $schema->resultset( 'TestReport' )->create( { report => {} } );
    like $row->id, qr{${HEX}{8}-${HEX}{4}-${HEX}{4}-${HEX}{4}-${HEX}{12}},
        'GUID is created automatically';
    isa_ok $row->created, 'DateTime', 'created column inflated to DateTime';
    is $row->report->{id}, $row->id, 'id field added to report';
    is $row->report->{created}, $row->created . 'Z', 'created field added to report';
};

subtest 'upload' => sub {
    my $expect_upload = $schema->resultset( 'Upload' )->create({
        type => 'cpan',
        dist => 'CPAN-Testers-Schema',
        version => '1.001',
        author => 'PREACTION',
        filename => 'CPAN-Testers-Schema-1.001.tar.gz',
        released => time,
    });

    my $row = $schema->resultset( 'TestReport' )->create({
        report => {
            distribution => {
                name => 'CPAN-Testers-Schema',
                version => '1.001',
            },
        },
    });

    my $got_upload = $row->upload;
    isa_ok $got_upload, 'CPAN::Testers::Schema::Result::Upload';
    is $got_upload->id, $expect_upload->id, 'upload object id is correct';
    is $got_upload->dist, $expect_upload->dist, 'upload object dist is correct';
    is $got_upload->filename, $expect_upload->filename, 'upload object filename is correct';
};

done_testing;

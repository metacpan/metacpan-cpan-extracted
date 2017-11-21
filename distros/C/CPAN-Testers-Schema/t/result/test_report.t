
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

subtest 'JSON decode problem on MySQL' => sub {
    if ( !eval { require Test::mysqld; 1 } ) {
        plan skip_all => 'Requires Test::mysqld';
        return;
    }

    no warnings 'once';
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '', # no TCP socket
        },
    );
    if ( !$mysqld ) {
        plan skip_all => "Failed to start up server: $Test::mysqld::errstr";
        return;
    }

    my ( undef, $version ) = DBI->connect( $mysqld->dsn(dbname => 'test') )->selectrow_array( q{SHOW VARIABLES LIKE 'version'} );
    my ( $mversion ) = $version =~ /^(\d+[.]\d+)/;
    diag "MySQL version: $version; Major version: $mversion";
    if ( $mversion < 5.7 ) {
        plan skip_all => "Need MySQL version 5.7 or higher. This is $version";
        return;
    }

    my $schema = CPAN::Testers::Schema->connect(
        $mysqld->dsn(dbname => 'test'), undef, undef, { ignore_version => 1 },
    );
    $schema->deploy;

    my $row = $schema->resultset( 'TestReport' )->create( {
        report => {
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
                version => '1.00',
            },
            result => {
                grade => 'pass',
                output => {
                    uncategorized => "1\x{001f}", # ASCII below 0x20
                },
            },
        },
    } );
    my $id = $row->id;

    my $got_row = $schema->resultset( 'TestReport' )->find( $id );
    is $got_row->report->{result}{output}{uncategorized}, "1\x{001f}",
        'output is deserialized correctly';

};

done_testing;

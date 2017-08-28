
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
    my $given_report = create_metabase_report(
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

    subtest 'update metabase fact with same GUID' => sub {
        my $given_report = create_metabase_report(
            grade => 'fail',
            distfile => 'PREACTION/Foo-Bar-6.24.tar.gz',
            distribution => 'Foo-Bar-6.24',
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
                version => '6.24',
            },
            result => {
                grade => 'fail',
                output => {
                    uncategorized => 'Test output',
                },
            },
        };

        my $existing_row = $schema->resultset( 'TestReport' )->create({
            id => $given_report->core_metadata->{guid},
            report => { foo => 'bar' },
        });

        my $new_row = $schema->resultset( 'TestReport' )->insert_metabase_fact( $given_report );
        my $got_report = $new_row->report;
        is_deeply $got_report, $expect_report, 'Row is updated and Metabase::Fact is converted';
    };
};

subtest 'dist() - fetch reports by language/dist' => sub {
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

    my %rows = (
        'Perl 5' => {
            'Foo-Bar-1.34' => $schema->resultset( 'TestReport' )->create( {
                report => create_json_report(
                    language => 'Perl 5',
                    grade => 'pass',
                    distribution => 'Foo-Bar',
                    version => '1.34',
                ),
            } ),
            'Foo-Bar-2.67' => $schema->resultset( 'TestReport' )->create( {
                report => create_json_report(
                    language => 'Perl 5',
                    grade => 'fail',
                    distribution => 'Foo-Bar',
                    version => '2.67',
                ),
            } ),
            'Fizz-Buzz-1.00' => $schema->resultset( 'TestReport' )->create( {
                report => create_json_report(
                    language => 'Perl 5',
                    grade => 'pass',
                    distribution => 'Fizz-Buzz',
                    version => '1.00',
                ),
            } ),
        },
        'Perl 6' => {
            'Foo-Bar-4.44' => $schema->resultset( 'TestReport' )->create( {
                report => create_json_report(
                    language => 'Perl 6',
                    grade => 'pass',
                    distribution => 'Foo-Bar',
                    version => '4.44',
                ),
            } ),
            'Fizz-Buzz-1.00' => $schema->resultset( 'TestReport' )->create( {
                report => create_json_report(
                    language => 'Perl 6',
                    grade => 'pass',
                    distribution => 'Fizz-Buzz',
                    version => '6.78',
                ),
            } ),
        },
    );

    subtest 'dist() without version' => sub {
        my $rs = $schema->resultset( 'TestReport' );
        $rs = $rs->dist( 'Perl 5', 'Foo-Bar' );
        is_deeply
            [ map { $_->id } $rs->all ],
            [ map { $_->id } $rows{'Perl 5'}->@{qw( Foo-Bar-1.34 Foo-Bar-2.67 )} ],
            'correct report ids found';
    };

    subtest 'dist() with version' => sub {
        my $rs = $schema->resultset( 'TestReport' );
        $rs = $rs->dist( 'Perl 5', 'Fizz-Buzz', '1.00' );
        is_deeply
            [ map { $_->id } $rs->all ],
            [ map { $_->id } $rows{'Perl 5'}->@{qw( Fizz-Buzz-1.00 )} ],
            'correct report ids found';
    };
};

done_testing;

#sub create_metabase_report
#
#   my $report = create_metabase_report(
#       grade => 'pass',
#       distfile => 'P/PR/PREACTION/Foo-Bar-1.24.tar.gz',
#       distribution => 'Foo-Bar-1.24',
#       textreport => 'Test output',
#       creator => 'metabase:user:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX',
#   );
#
# Create a new metabase report to submit. Returns a data structure
# suitable to be encoded into JSON and submitted.
#
# This code is stolen from:
#   * Test::Reporter::Transport::Metabase sub send
#   * Metabase::Client::Simple sub submit_fact

sub create_metabase_report( %attrs ) {
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
        perl_version => 'v5.12.0', # Some have a leading "v", some do not
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

#sub create_json_report
#
#   my $report = create_json_report(
#       grade => 'pass',
#       distribution => 'Foo-Bar',
#       version => '1.24',
#       language => 'Perl 5',
#   );
#
# Create a JSON report suitable to be stored in the database. Most of
# the data is set to sane defaults, leaving only the testable data to
# change.

sub create_json_report( %args ) {
    my $report = {
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
                name => $args{language} || 'Perl 5',
                archname => 'x86_64-linux',
                version => '5.12.0',
            },
        },
        distribution => {
            name => $args{distribution},
            version => $args{version},
        },
        result => {
            grade => $args{grade},
            output => {
                uncategorized => 'Test output',
            },
        },
    };

    return $report;
}


use Mojo::Base '-strict';
use experimental 'signatures', 'postderef';
no warnings 'once';
use Test::More;
use Test::Mojo;
use FindBin qw( $Bin );
use File::Spec::Functions qw( catfile catdir );
use Mojo::File qw( path );
use Test::Reporter;
use CPAN::Testers::Report;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Fact::LegacyReport;
use Metabase::User::Profile;
use Mojo::Util qw( b64_encode );
eval { require Test::mysqld } or plan skip_all => 'Requires Test::mysqld';

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    },
) or plan skip_all => $Test::mysqld::errstr;

use Mojo::JSON qw( to_json );

my $SHARE_DIR = path( $Bin, '..', 'share' );
my $bin_path = path( $Bin, '..', '..', 'bin', 'cpantesters-legacy-metabase' );
require $bin_path;
my $t = Test::Mojo->new;

my $schema = $t->app->schema(
    CPAN::Testers::Schema->connect(
        $mysqld->dsn(dbname => 'test')
    )
);
$schema->deploy;

subtest 'post report' => sub {
    my %creator = (
        full_name => 'Doug Bell',
        email_address => 'doug@preaction.me',
    );
    my $creator = Metabase::User::Profile->create( %creator );

    my $auth = b64_encode( join ":", $creator->core_metadata->{guid}, 'SECRET' );
    chomp $auth;
    my %headers = (
        Authorization => "Basic $auth",
    );

    my %given_data = (
        grade => 'pass',
        distfile => 'PREACTION/Foo-Bar-1.24.tar.gz',
        distribution => 'Foo-Bar-1.24',
        textreport => 'Test output',
        creator => $creator->resource,
    );
    my $given_report = create_report( %given_data );
    my $guid = $given_report->core_metadata->{guid};

    subtest 'user auth fails' => sub {
        $t->post_ok( '/api/v1/submit/CPAN-Testers-Report' => \%headers, json => $given_report->as_struct )
          ->status_is( 401 )
          ->or( sub { diag explain shift->tx->res->body } )
          ;
    };

    subtest 'check if user exists' => sub {
        $t->head_ok( '/api/v1/guid/' . $guid )
          ->status_is( 404 )
          ->or( sub { diag explain shift->tx->res->body } )
          ;
    };

    subtest 'create user' => sub {
        $t->post_ok( '/api/v1/register' => json => $creator->as_struct )
          ->status_is( 200 )
          ->or( sub { diag explain shift->tx->res->body } )
          ;
    };

    subtest 'retry post' => sub {
        $t->post_ok( '/api/v1/submit/CPAN-Testers-Report' => \%headers, json => $given_report->as_struct )
          ->status_is( 201 )
          ->or( sub { diag explain shift->tx->res->body } )
          ->header_is( Location => '/api/v1/guid/' . $guid )
          ->json_is( { guid => $guid } );

        my $row = $schema->resultset( 'TestReport' )->find( $guid );
        ok $row, 'row found by guid';
        is $row->created . 'Z', $given_report->core_metadata->{creation_time}, 'created is correct';

        is $row->report->{reporter}{name}, $creator{full_name},
            'reporter name is correct';
        is $row->report->{reporter}{email}, $creator{email_address},
            'reporter email is correct';
        is $row->report->{result}{grade}, lc $given_data{grade},
            'report grade is correct';
        is $row->report->{result}{output}{uncategorized}, $given_data{textreport},
            'report text is correct';
        is $row->report->{distribution}{name}, 'Foo-Bar',
            'dist name is correct';
        is $row->report->{distribution}{version}, '1.24',
            'dist version is correct';

        is $row->report->{environment}{system}{osname}, 'linux',
            'osname is correct';
        is $row->report->{environment}{system}{osversion}, '2.14.4',
            'osname is correct';
        is $row->report->{environment}{language}{name}, 'Perl 5',
            'language name is correct';
        is $row->report->{environment}{language}{version}, '5.12.0',
            'language version is correct';
        is $row->report->{environment}{language}{archname}, 'x86_64-linux',
            'language arch is correct';
    };

    subtest 'tail/log.txt' => sub {

        my $upload = $schema->resultset( 'Upload' )->create({
            type => 'cpan',
            dist => 'CPAN-Testers-Schema',
            version => '1.001',
            author => 'PREACTION',
            filename => 'CPAN-Testers-Schema-1.001.tar.gz',
            released => time,
        });

        my %date = (
            year => 2017,
            month => 1,
            day => 1,
            hour => 0,
            minute => 0,
            second => 0
        );
        my $row = $schema->resultset( 'TestReport' )->create({
            created => DateTime->new( %date ),
            report => {
                reporter => {
                    name => 'Doug Bell',
                },
                environment => {
                    language => {
                        name => 'Perl 5',
                        version => 'v5.24.0',
                        archname => 'x86_64-linux',
                    },
                },
                distribution => {
                    name => 'CPAN-Testers-Schema',
                    version => '1.001',
                },
                result => {
                    grade => 'pass',
                },
            },
        });
        my $guid = $row->id;

        # Add some extra rows to ignore for now
        $schema->resultset( 'TestReport' )->create({
            created => DateTime->new( %date ),
            report => {
                reporter => {
                    name => 'Doug Bell',
                },
                environment => {
                    language => {
                        name => 'Perl 6',
                        version => '2017.05',
                        archname => 'x86_64-darwin',
                    },
                },
                distribution => {
                    name => 'Perl6-Derp',
                    version => '1.001',
                },
                result => {
                    grade => 'pass',
                },
            },
        });

        $t->get_ok( '/tail/log.txt' )
          ->content_like( qr{The last \d+ reports as of \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z:} )
          ->content_like( qr{\Q[2017-01-01T00:00:00Z] [Doug Bell] [pass] [PREACTION/CPAN-Testers-Schema-1.001.tar.gz] [x86_64-linux] [perl-v5.24.0] [$guid] [2017-01-01T00:00:00Z]} )
          ->content_unlike( qr{\Q[perl-v2017.05]}, 'does not read Perl 6 reports' )
          ;
    };
};

done_testing;

#sub create_report
#
#   my $report = create_report(
#       grade => 'pass',
#       distfile => 'P/PR/PREACTION/Foo-Bar-1.24.tar.gz',
#       distribution => 'Foo-Bar-1.24',
#       comments => 'Test output',
#       from => 'doug@example.com (PREACTION)',
#   );
#
# Create a new report to submit. Returns a data structure suitable to be
# encoded into JSON and submitted.
#
# This code is stolen from:
#   * Test::Reporter::Transport::Metabase sub send
#   * Metabase::Client::Simple sub submit_fact

sub create_report( %args ) {
    my $creator = delete $args{creator};
    my $textreport = delete $args{textreport};
    my $report = Test::Reporter->new( transport => 'Null', %args );

    # Build CPAN::Testers::Report with its various component facts.
    my $metabase_report = CPAN::Testers::Report->open(
        resource => 'cpan:///distfile/' . $report->distfile,
        creator => $creator,
    );

    $metabase_report->add( 'CPAN::Testers::Fact::LegacyReport' => {
        grade => $report->grade,
        osname => 'linux',
        osversion => '2.14.4',
        archname => 'x86_64-linux',
        perl_version => '5.12.0',
        textreport => $textreport,
    });

    # TestSummary happens to be the same as content metadata 
    # of LegacyReport for now
    $metabase_report->add( 'CPAN::Testers::Fact::TestSummary' =>
        [$metabase_report->facts]->[0]->content_metadata()
    );

    $metabase_report->close();

    return $metabase_report;
}


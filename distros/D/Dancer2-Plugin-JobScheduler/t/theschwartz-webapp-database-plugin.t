#!perl
# no critic (Modules::ProhibitMultiplePackages)

use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

# use Test2::Plugin::BailOnFail;

# Add t/lib to @INC
use FindBin 1.51 qw( $RealBin );
use File::Spec;
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, 'lib' );
}
use lib "$lib_path";

use Test::WWW::Mechanize::PSGI;
use HTTP::Request::Common;
use Crypt::JWT qw(encode_jwt decode_jwt);
use JSON       qw( to_json from_json );

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use Dancer2::Plugin::JobScheduler::Testing::Utils qw( :all );
use Database::Temp;

my $test_db;

BEGIN {
    # Create test databases

    my $driver = 'SQLite';
    $test_db = Database::Temp->new(
        driver  => $driver,
        cleanup => 0,
        init    => sub {
            my ( $dbh, $name ) = @_;
            init_db( $driver, $dbh, $name );
        },
    );

}

my %job_scheduler_plugin_config = (
    default    => 'theschwartz',
    schedulers => {
        theschwartz => {
            client     => 'TheSchwartz',
            parameters => {
                handle_uniqkey => 'acknowledge',
                databases      => {
                    dancer_app_db => {
                        prefix => q{},
                    },
                },
                dbh_callback => 'replaced-when-calling',
            }
        }
    }
);
my %database_plugin_config = (
    connections => {
        dancer_app_db => { db_2_dancer2_plugin_database_config($test_db), },
    },
);

{

    package Dancer2::Plugin::JobScheduler::Testing::TheSchwartz::WebApp::All;

    # request_data command available in Dancer2 0.301000
    use Dancer2 0.301;
    use HTTP::Status qw( :constants status_message );

    BEGIN {
        set log => 'debug';
        set plugins => {
            JobScheduler => \%job_scheduler_plugin_config,
            Database     => \%database_plugin_config,
        };
    }
    use Dancer2::Plugin::JobScheduler;
    use Dancer2::Plugin::Database;

    set serializer => 'JSON';

    post qr{/submit_job/(?<task_name>[[:word:]_-]{1,})$}msx => sub {
        my $h = request_data;
        my %r = submit_job(
            client => 'theschwartz',
            job    => {
                task => captures->{task_name},
                args => $h->{'args'},
                opts => $h->{'opts'},
            },
            opts => {

                # database is the keyword and command from
                # Dancer2::Plugin::Database. It takes one argument:
                # the database name, similar to our dbh_callback.
                dbh_callback => \&database,
            },
        );
        status HTTP_OK;
        return \%r;
    };

    get qr{/list_jobs/(?<task_name>[[:word:]_-]{1,})$}msx => sub {
        my %r = list_jobs(
            client        => 'theschwartz',
            search_params => {
                task => captures->{task_name},
            },
            opts => {
                dbh_callback => \&database,
            },
        );
        status HTTP_OK;
        return \%r;
    };

}

my $app = Dancer2::Plugin::JobScheduler::Testing::TheSchwartz::WebApp::All->to_app;
is( ref $app, 'CODE', 'Initialized the test app' );

# Activate web app
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

# List jobs, get 0
$mech->get_ok(q{/list_jobs/task_3});

# diag $mech->content;
is(
    from_json( $mech->content ),
    {
        error   => undef,
        status  => 'OK',
        success => 1,
        jobs    => []
    },
    'Correct return'
);

# Submit a job with ID 1
$mech->post(
    q{/submit_job/task_2},
    content => to_json(
        {
            args => { name       => 'My Name', age => 204 },
            opts => { unique_key => 'UNIQ_123' },
        }
    )
);
is( from_json( $mech->content ), { error => undef, status => 'OK', success => 1, id => 1, }, 'Correct return' );

# Submit a job with ID 2
$mech->post(
    q{/submit_job/task_3},
    content => to_json(
        {
            args => { name       => 'My Name', age => 204 },
            opts => { unique_key => 'UNIQ_123' },
        }
    )
);
is( from_json( $mech->content ), { error => undef, status => 'OK', success => 1, id => 2, }, 'Correct return' );

# List jobs, get 1
$mech->get_ok(q{/list_jobs/task_3});

# diag $mech->content;
is(
    from_json( $mech->content ),
    {
        error   => undef,
        status  => 'OK',
        success => 1,
        jobs    => [ { task => 'task_3', args => { name => 'My Name', age => 204 }, opts => { unique_key => 'UNIQ_123' }, }, ]
    },
    'Correct return'
);

# Create two jobs with the same unique key for task 'task_4'.
# The second job insert will not do anything.

# Submit a job with ID 3, task_4
$mech->post(
    q{/submit_job/task_4},
    content => to_json(
        {
            args => { name       => 'My Name', age => 204 },
            opts => { unique_key => 'UNIQ_123' },
        }
    )
);
is( from_json( $mech->content ), { error => undef, status => 'OK', success => 1, id => 3 }, 'Correct return' );

# Submit same job again. Get back the same job id.
$mech->post(
    q{/submit_job/task_4},
    content => to_json(
        {
            args => { name       => 'My Name', age => 204 },
            opts => { unique_key => 'UNIQ_123' },
        }
    )
);
is( from_json( $mech->content ), { error => undef, status => 'OK', success => 1, id => 3 }, 'Correct return' );

# Undefine all Database::Temp objects explicitly to demolish
# the databases in good order, instead of doing it unmanaged
# during global destruct, when program dies.
$test_db = undef;

done_testing;

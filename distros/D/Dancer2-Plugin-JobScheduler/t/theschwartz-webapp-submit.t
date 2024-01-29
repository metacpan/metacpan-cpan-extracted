#!perl
## no critic (Modules::ProhibitMultiplePackages)

use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

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
use JSON       qw( to_json );

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use Dancer2::Plugin::JobScheduler::Testing::Utils qw( :all );
use Database::Temp;

my $test_db;

BEGIN {
    # Create only one test database

    my $driver = 'SQLite';
    $test_db = Database::Temp->new(
        driver  => $driver,
        cleanup => 1,
        init    => sub {
            my ( $dbh, $name ) = @_;
            init_db( $driver, $dbh, $name );
        },
    );

    {

        package Dancer2::Plugin::JobScheduler::Testing::Database::ManagedHandleConfigLocal;
        use Moo;
        use Dancer2::Plugin::JobScheduler::Testing::Utils qw( :all );
        has config => (
            is      => 'ro',
            default => sub {
                return {
                    default   => q{theschwartz_db1},
                    databases => {
                        theschwartz_db1 => { db_2_managed_handle_config($test_db), },
                    },
                };
            },
        );
        1;
    }

    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $ENV{DATABASE_MANAGED_HANDLE_CONFIG} = 'Dancer2::Plugin::JobScheduler::Testing::Database::ManagedHandleConfigLocal';

    use Database::ManagedHandle;
    Database::ManagedHandle->instance;
}

my %plugin_config = (
    default    => 'theschwartz',
    schedulers => {
        theschwartz => {
            client     => 'TheSchwartz',
            parameters => {
                dbh_callback => 'Database::ManagedHandle->instance',
                databases    => {
                    theschwartz_db1 => {},
                }
            }
        }
    }
);

{

    package Dancer2::Plugin::JobScheduler::Testing::TheSchwartz::WebApp::Submit;
    use Dancer2;
    use HTTP::Status qw( :constants status_message );

    BEGIN {
        set log     => 'debug';
        set plugins => { JobScheduler => \%plugin_config, };
    }
    use Dancer2::Plugin::JobScheduler;

    get q{/} => sub {
        status HTTP_OK;
        return 'OK';
    };

    get q{/config} => sub {
        status HTTP_OK;
        return to_json( config->{'plugins'}->{'JobScheduler'}, { utf8 => 1, canonical => 1, } );
    };

    get q{/submit_job} => sub {
        my %r = submit_job(
            client => 'theschwartz',
            job    => {
                task => 'task1',
                args => { name => 'Mikko', age => 123 },
                opts => {},
            },
        );
        status HTTP_OK;
        return to_json( \%r, { utf8 => 1, canonical => 1, } );
    };

    get q{/list_jobs} => sub {
        my %r = list_jobs(
            client        => 'theschwartz',
            search_params => {
                task => 'task1',
            },
        );
        status HTTP_OK;
        return to_json( \%r, { utf8 => 1, canonical => 1, } );
    };

}

my $app = Dancer2::Plugin::JobScheduler::Testing::TheSchwartz::WebApp::Submit->to_app;
is( ref $app, 'CODE', 'Initialized the test app' );

# Activate web app
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

$mech->get_ok(q{/});
$mech->content_is( q{OK}, 'Correct return' );

# Check configuration
$mech->get_ok(q{/config});
$mech->content_is( to_json( \%plugin_config, { utf8 => 1, canonical => 1, } ), 'Correct return' );

# List jobs, get 0
$mech->get_ok(q{/list_jobs});
$mech->content_is(
    to_json(
        {
            error   => undef,
            status  => 'OK',
            success => 1,
            jobs    => []
        },
        { utf8 => 1, canonical => 1, }
    ),
    'Correct return'
);

# Submit a job
$mech->get_ok(q{/submit_job});
$mech->content_is( to_json( { error => undef, status => 'OK', success => 1, id => 1, }, { utf8 => 1, canonical => 1, } ),
    'Correct return' );

# List jobs, get 1
$mech->get_ok(q{/list_jobs});
$mech->content_is(
    to_json(
        {
            error   => undef,
            status  => 'OK',
            success => 1,
            jobs    => [ { task => 'task1', args => { name => 'Mikko', age => 123 }, opts => {}, }, ]
        },
        { utf8 => 1, canonical => 1, }
    ),
    'Correct return'
);

# Undefine all Database::Temp objects explicitly to demolish
# the databases in good order, instead of doing it unmanaged
# during global destruct, when program dies.
$test_db = undef;

done_testing;

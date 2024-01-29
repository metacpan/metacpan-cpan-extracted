#!/perl
use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::WWW::Mechanize::PSGI;
use HTTP::Request::Common;
use Crypt::JWT qw(encode_jwt decode_jwt);
use Database::ManagedHandle;

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

my %plugin_config = (
    default    => 'theschwartz',
    schedulers => {
        theschwartz => {
            package    => 'TheSchwartz',
            parameters => {
                database_handle_callback => 'Database::ManagedHandle->instance',
                databases                => [
                    {
                        id     => 'theschwartz_db1',
                        prefix => q{},
                    },
                ]
            }
        }
    }
);
{

    package TestProgram;
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
}

my $app = TestProgram->to_app;
is( ref $app, 'CODE', 'Got the test app' );

# Activate web app
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );
$mech->get_ok(q{/});
$mech->content_is( q{OK}, 'Correct return' );

# Check configuration
$mech->get_ok(q{/config});
use JSON qw( to_json );
$mech->content_is( to_json( \%plugin_config, { utf8 => 1, canonical => 1, } ), 'Correct return' );

done_testing();

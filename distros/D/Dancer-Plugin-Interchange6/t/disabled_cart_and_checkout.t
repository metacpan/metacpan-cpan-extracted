use lib 't/lib';
use Test::More import => ['!pass'];
use Test::Exception;
use Test::WWW::Mechanize::PSGI;
use Dancer;
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Interchange6::Routes;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

{
    package Fixtures;
    use Moo;
    with 'Interchange6::Test::Role::Fixtures';

    has ic6s_schema => (
        is => 'ro',
    );

    1;
}

setting('plugins')->{DBIC} = {
    default => {
        schema_class => 'Interchange6::Schema',
        connect_info => [
            "dbi:SQLite:dbname=:memory:",
            undef, undef,
            {
                sqlite_unicode  => 1,
                on_connect_call => 'use_foreign_keys',
                on_connect_do   => 'PRAGMA synchronous = OFF',
                quote_names     => 1,
            }
        ]
    }
};

set logger => 'capture';
set log    => 'error';

my $trap = Dancer::Logger::Capture->trap;

my ( $schema, $fixtures );

subtest "deploy and install fixtures" => sub {

    lives_ok { $schema = shop_schema } "Connect to schema"
      or diag explain $trap->read;

    lives_ok { $schema->deploy } "Deploy schema" or diag explain $trap->read;

    lives_ok { $fixtures = Fixtures->new( ic6s_schema => $schema ) }
    "get fixtures"
      or diag explain $trap->read;

    lives_ok { $fixtures->navigation } "deploy navigation fixtures"
      or diag explain $trap->read;
};

set session => 'DBIC';
set session_options => { schema => $schema, };

set template => 'template_flute';    # for coverage testing only
setting('plugins')->{'Interchange6::Routes'} = {
    cart     => { active  => 0 },
    checkout => { active  => 0 },
};

# we want navigation->records to be undef
my $settings = setting('plugins');
delete $settings->{'Interchange6::Routes'}->{navigation};

my $app = sub {
    my $env = shift;
    shop_setup_routes;
    my $request = Dancer::Request->new( env => $env );
    Dancer->dance($request);
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

subtest "cart route not defined" => sub {

    $mech->get('/cart');

    ok $mech->status eq '404', "/cart not found" or diag $mech->status;
};

subtest "checkout route not defined" => sub {

    $mech->get('/checkout');

    ok $mech->status eq '404', "/checkout not found" or diag $mech->status;
};

subtest "navigation with undef records" => sub {

    $trap->read;
    $mech->get('/hand-tools');

    ok $mech->status eq '500', "/hand-tools crashed" or diag $mech->status;

    cmp_ok $trap->read->[0]->{message}, 'eq',
      'Supplied view (category) not found -  does not exist',
      "got view not found error (as expected)";
};

done_testing;

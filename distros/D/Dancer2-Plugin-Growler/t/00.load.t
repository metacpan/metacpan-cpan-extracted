use Test::More tests => 4;

use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

diag("Testing Dancer2::Plugin::Growler $Dancer2::Plugin::Growler::VERSION");

# TODO: do tests outside of app between routes, see bottom of test for a note on why we can't do that ATM

package YourDancerApp {
    use Dancer2;
    use Dancer2::Plugin::Growler;
    get '/' => sub {
        my $pre_growls = growls();
        Test::More::is( $pre_growls, undef, 'first call growls() is undef' );
        growl("I am growl()");
        growl( "I am growl() w/ null type", { type => undef } );
        growl_info("I am info() growl");
        growl_success("I am success() growl");
        growl_warning("I am warning() growl");
        growl_warning( "I am warning() growl that yuo can't kill",                           { allow_dismiss => 0 } );
        growl_warning( "I am warning() growl that yuo can't kill that sticks arounf longer", { allow_dismiss => 0, delay => 10_000 } );
        growl_warning( "I am warning() growl that disallows permanent undismissable growls", { allow_dismiss => 0, delay => 0 } );
        growl_error("I am error() growl");

        Test::More::is_deeply(
            growls(),

            [
                {
                    'message' => 'I am growl()',
                    'options' => {}
                },
                {
                    'message' => 'I am growl() w/ null type',
                    'options' => { 'type' => undef }
                },
                {
                    'message' => 'I am info() growl',
                    'options' => { 'type' => 'info' }
                },
                {
                    'message' => 'I am success() growl',
                    'options' => { 'type' => 'success' }
                },
                {
                    'message' => 'I am warning() growl',
                    'options' => { 'type' => 'warning' }
                },
                {
                    'message' => 'I am warning() growl that yuo can\'t kill',
                    'options' => {
                        'allow_dismiss' => 0,
                        'type'          => 'warning'
                    }
                },
                {
                    'message' => 'I am warning() growl that yuo can\'t kill that sticks arounf longer',
                    'options' => {
                        'allow_dismiss' => 0,
                        'delay'         => 10000,
                        'type'          => 'warning'
                    }
                },
                {
                    'message' => 'I am warning() growl that disallows permanent undismissable growls',
                    'options' => {
                        'allow_dismiss' => 1,
                        'delay'         => 0,
                        'type'          => 'warning'
                    }
                },
                {
                    'message' => 'I am error() growl',
                    'options' => { 'type' => 'danger' }
                }
            ],
            'calling growls() returns expected list'
        );

        Test::More::is_deeply( growls(), [], 'growls() did clear out the list' );

        return "hi";
    };
};

my $app  = YourDancerApp->to_app;
my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );
is( $res->content(), 'hi', 'sanity: request happened without issue' );

# TODO: the cookies do not stick* so we can't test between submissions ATM since the behavior is session based
# $jar->add_cookie_header($req); does not modify $req

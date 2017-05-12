use Test::More;

use App::Kit::cPanel;

my $app = App::Kit::cPanel->instance;

isa_ok( $app, 'App::Kit::cPanel' );
isa_ok( $app, 'App::Kit' );

SKIP: {
    eval 'require Cpanel;';
    skip "cPanel module tests can only run on cPanel servers", 2 if $@;
    isa_ok( $app->log,    'Cpanel::Logger' );
    isa_ok( $app->locale, 'Cpanel::Locale' );
}

done_testing;

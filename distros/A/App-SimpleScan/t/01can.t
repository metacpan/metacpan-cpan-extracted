use Test::More tests => 2;

BEGIN {
use_ok( 'App::SimpleScan' );
}

my $app = new App::SimpleScan;
can_ok $app, qw(new go transform_test_specs
                handle_options app_defaults
                install_options parse_command_line 
                install_pragma_plugins
                pragma  stack_code stack_test
                finalize_tests );


use Test::More tests => 9;

BEGIN {
use_ok( 'Acme::PricelessMethods' );
}

diag( "Testing Acme::PricelessMethods $Acme::PricelessMethods::VERSION" );

my $acmer = Acme::PricelessMethods->new;

isa_ok( $acmer, 'Acme::PricelessMethods');

can_ok( $acmer, qw/is_perl_installed
                   is_machine_on
                   universe_still_exists
                   is_program_running
                   is_time_moving_forward
                   is_true_true/ );

ok( $acmer->is_perl_installed );
ok( $acmer->is_machine_on );
ok( $acmer->universe_still_exists );
ok( $acmer->is_program_running );
ok( $acmer->is_time_moving_forward );
ok( $acmer->is_true_true );


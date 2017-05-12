use Test::More tests => 1;

use Acme::Laugh qw( laugh );

diag( "Testing Acme::Laugh $Acme::Laugh::VERSION" );

my $laugh = laugh(10);
ok(length($laugh) > 10, "laugh length more or less correct");
diag( $laugh );

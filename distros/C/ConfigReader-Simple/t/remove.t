use Test::More tests => 5;

use ConfigReader::Simple;

my @Directives = qw( Test1 Test2 Test3 Test4 );

my $config = ConfigReader::Simple->new( "t/example.config", \@Directives );
isa_ok( $config, 'ConfigReader::Simple' );

# remove things that do exist
is( $config->get( 'Test3' ), 'foo', 'Test3 has the right value' );
ok( $config->remove( 'Test3' ), 'Test3 is removed' );

my $value =  not $config->exists( 'Test3' );
ok( $value, 'Test3 no longer exists' );

# remove things that do not exist
$value = not $config->remove( 'Tenor' );
ok( $value, 'Tenor does not exist, but was removed' );

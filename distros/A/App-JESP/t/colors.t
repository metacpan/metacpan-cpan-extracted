#! perl -w

use Test::Most;
use App::JESP;

use Term::ANSIColor;
use Log::Any::Adapter qw/Stderr/;

ok( my $jesp = App::JESP->new({ dsn => 'dbi:SQLite:dbname=:memory:', username => undef, password => undef, home => 'bla', interactive => 1 }) );
is( $jesp->colorizer()->colored("Foo", "blue") , Term::ANSIColor::colored("Foo", "blue") );

done_testing();

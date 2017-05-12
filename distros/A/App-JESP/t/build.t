#! perl -w

use Test::Most;
use App::JESP;

use Log::Any::Adapter qw/Stderr/;

ok( my $jesp = App::JESP->new({ dsn => 'dbi:SQLite:dbname=:memory:', username => undef, password => undef, home => 'bla' }) );
is( $jesp->prefix() , 'jesp_' );
ok( $jesp->dbix_simple(), "Ok can get DBIx::Simple DB");

done_testing();

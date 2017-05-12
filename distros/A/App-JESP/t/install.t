#! perl -w

use Test::Most;
use App::JESP;

# use Log::Any::Adapter qw/Stderr/;

ok( my $jesp = App::JESP->new({ dsn => 'dbi:SQLite:dbname=:memory:', username => undef, password => undef, home => 'bla' }) );
ok( $jesp->install(), "Ok can install JESP in the given Database");

my @installed_patches  = $jesp->dbix_simple()->select( $jesp->patches_table_name() )->hashes();

is( scalar( @installed_patches ) , 1 );
is( $installed_patches[0]->{id} , $jesp->prefix().'meta_zero' , "Good zero name" );
ok( exists( $installed_patches[0]->{applied_datetime} ) , "There is an applied time" );

# Try pushing a patch in the meta patches, and check that it becomes applied.
push @{$jesp->meta_patches()},
    {
        id => $jesp->prefix().'meta_dummy',
        sql => 'ALTER TABLE '.$jesp->patches_table_name().' ADD COLUMN some_dummy_column VARCHAR(512);',
    };

ok( $jesp->install() );
{
    my @installed_patches  = $jesp->dbix_simple()->select( $jesp->patches_table_name() , ['id', 'some_dummy_column' ] )->hashes();
    is( scalar( @installed_patches ) , 2 );
    ok( exists( $installed_patches[0]->{some_dummy_column} ) , "The new dummy column is there" );
}

done_testing();

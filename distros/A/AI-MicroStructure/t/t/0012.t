use Data::Dumper;
use Test::More tests => 6;
use strict;
use AI::MicroStructure;


AI::MicroStructure->add_structure(
    ams_test_beatles => [ qw(john paul george ringo) ]
);

my $fab4 = AI::MicroStructure::ams_test_beatles->new();
my @fab = $fab4->name(1);
is( @fab, 0, "Single item" );
@fab = $fab4->name(0);
is( @fab, 0, "Four items" );

@fab = sort $fab4->name( 0 );
no warnings;
my @all = sort @cAI::MicroStructure::ams_test_beatles::List;
is_deeply( \@fab, \@all, "All items" );

# test for empty lists
AI::MicroStructure->add_structure( ams_test_null => [ ] );
my $null = AI::MicroStructure::ams_test_null->new();

my @null = $null->name;
is( @null, 0, "Single item (none)" );
@null = $null->name(  );
is( @null, 0, "Four items (none)" );

@null = sort $null->name( 0 );
no warnings;
@all = sort @AI::MicroStructure::ams_test_null::List;
is_deeply( \@null, \@all, "All items (none)" );


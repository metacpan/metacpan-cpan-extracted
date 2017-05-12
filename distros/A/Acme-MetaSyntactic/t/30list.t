use Test::More tests => 6;
use strict;
use Acme::MetaSyntactic;

Acme::MetaSyntactic->add_theme(
    ams_test_beatles => [ qw(john paul george ringo) ]
);

my $fab4 = Acme::MetaSyntactic::ams_test_beatles->new();

my @fab = $fab4->name; 
is( @fab, 1, "Single item" );
@fab = $fab4->name( 4 );
is( @fab, 4, "Four items" );

@fab = sort $fab4->name( 0 );
no warnings;
my @all = sort @Acme::MetaSyntactic::ams_test_beatles::List;
is_deeply( \@fab, \@all, "All items" );

# test for empty lists
Acme::MetaSyntactic->add_theme( ams_test_null => [ ] );
my $null = Acme::MetaSyntactic::ams_test_null->new();

my @null = $null->name; 
is( @null, 0, "Single item (none)" );
@null = $null->name( 4 );
is( @null, 0, "Four items (none)" );

@null = sort $null->name( 0 );
no warnings;
@all = sort @Acme::MetaSyntactic::ams_test_null::List;
is_deeply( \@null, \@all, "All items (none)" );


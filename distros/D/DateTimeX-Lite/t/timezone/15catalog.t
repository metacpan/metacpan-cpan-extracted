use strict;
use warnings;

use File::Spec;
use Test::More;

use DateTimeX::Lite::TimeZone;


plan tests => 31;

{
    my @all = DateTimeX::Lite::TimeZone::all_names();
    ok( scalar @all > 50, 'there are more than 50 names in the catalog' );
    note( "Available timezones: ", explain(\@all) );
    ok( ( grep { $_ eq 'America/Chicago' } @all ),
        'America/Chicago is in the list of all names' );

    my $all = DateTimeX::Lite::TimeZone::all_names();
    ok( ref $all, 'all_names() returns ref in scalar context' );
}

{
    my @cats = DateTimeX::Lite::TimeZone::categories();
    note( "Available categories: ", explain(\@cats) );
    my %cats = map { $_ => 1 } @cats;
    for my $c ( qw( Africa
                    America
                    Antarctica
                    Asia
                    Atlantic
                    Australia
                    Europe
                    Indian
                    Pacific
                  ) )
    {
        ok( $cats{$c}, "$c is in categories list" );
    }

    my $cats = DateTimeX::Lite::TimeZone::categories();
    ok( ref $cats, 'categories() returns ref in scalar context' );
}

{
    my %links = DateTimeX::Lite::TimeZone::links();
    note( "Available links: ", explain(\%links) );

    is( $links{Israel}, 'Asia/Jerusalem', 'Israel links to Asia/Jerusalem' );
    is( $links{UCT}, 'UTC', 'UCT links to UTC' );

    my $links = DateTimeX::Lite::TimeZone::links();
    ok( ref $links, 'links() returns ref in scalar context' );
}


{
    my @names = DateTimeX::Lite::TimeZone::names_in_category('America');
    my %names = map { $_ => 1 } @names;
    for my $n ( qw( Chicago Adak ) )
    {
        ok( exists $names{$n}, "$n is in America category" );
    }

    my $names = DateTimeX::Lite::TimeZone::names_in_category('America');
    ok( ref $names, 'names_in_category() returns ref in scalar context' );
}

{
    my @names = DateTimeX::Lite::TimeZone->names_in_category('America');
    my %names = map { $_ => 1 } @names;
    for my $n ( qw( Chicago Adak ) )
    {
        ok( exists $names{$n}, "$n is in America category (names_in_category() called as class method)" );
    }
}

{
    my @countries = DateTimeX::Lite::TimeZone::countries();
    my %countries = map { $_ => 1 } @countries;
    for my $c ( qw( jp us ) )
    {
        ok( exists $countries{$c}, "$c is in the list of countries" );
    }
}

{
    my @zones = DateTimeX::Lite::TimeZone::names_in_country('jp');
    is( @zones, 1, 'one zone for Japan' );
    is( $zones[0], 'Asia/Tokyo', 'zone for Japan is Asia/Tokyo' );
}

{
    my @zones = DateTimeX::Lite::TimeZone::names_in_country('JP');
    is( @zones, 1, 'one zone for Japan' );
    is( $zones[0], 'Asia/Tokyo', 'zone for Japan is Asia/Tokyo (uc country code)' );
}

{
    my @zones = DateTimeX::Lite::TimeZone->names_in_country('cl');
    is( @zones, 2, 'two zones for Chile' );
    is_deeply( [ sort @zones ],
               [ 'America/Santiago', 'Pacific/Easter' ],
               'zones for Chile are America/Santiago and Pacific/Easter' );
}

{
    my @zones = DateTimeX::Lite::TimeZone::names_in_country('us');
    is( $zones[0], 'America/New_York',
        'First timezone by country in US is America/New_York' );
}

{
    my $zones = DateTimeX::Lite::TimeZone::names_in_country('us');
    is( $zones->[0], 'America/New_York',
        'First timezone by country in US is America/New_York - scalar context' );
}

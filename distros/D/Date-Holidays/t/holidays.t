
use strict;
use warnings;
use Test::More; # done_testing
use Test::Fatal qw(dies_ok);
use Env qw($TEST_VERBOSE);

my $dh;

BEGIN {
    use lib qw(lib ../lib);
    use_ok('Date::Holidays');
}

SKIP: {
    eval { require Date::Holidays::AT };
    skip "Date::Holidays::AT not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'at' ),
        'Testing Date::Holidays::AT' );

    ok( $dh->holidays( YEAR => 2017 ),
        'Testing holidays with argument for Date::Holidays::AT' );
}

SKIP: {
    eval { require Date::Holidays::AU };
    skip "Date::Holidays::AU not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'au' ),
        'Testing Date::Holidays::AU' );

    ok( $dh->holidays( year => 2006 ),
        'Testing holidays for Date::Holidays::AU' );

    ok( $dh->holidays(
            year  => 2006,
            state => 'VIC',
        ),
        'Testing holidays for Date::Holidays::AU'
    );
}

SKIP: {
    eval { require Date::Holidays::BR };
    skip "Date::Holidays::BR not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'br' ),
        'Testing Date::Holidays::BR' );

    ok( $dh->holidays( year => 2004 ),
        'Testing holidays for Date::Holidays::BR' );
}

SKIP: {
    eval { require Date::Holidays::BY };
    skip "Date::Holidays::BY not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'by' ),
        'Testing Date::Holidays::BY' );

    ok( $dh->holidays( year => 2017 ),
        'Testing holidays with argument for Date::Holidays::BY' );
}

SKIP: {
    eval { require Date::Holidays::CA };
    skip "Date::Holidays::CA not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'ca' ),
        'Testing Date::Holidays::CA' );

    ok( $dh->holidays( year => 2004 ),
        'Testing holidays for Date::Holidays::CA' );
}

SKIP: {
    eval { require Date::Holidays::DE };
    skip "Date::Holidays::DE not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'de' ),
        'Testing Date::Holidays::DE' );

    ok( $dh->holidays(),
        'Testing holidays with no arguments for Date::Holidays::DE' );

    ok( $dh->holidays( year => 2006 ),
        'Testing holidays with argument for Date::Holidays::DE' );
}

SKIP: {
    eval { require Date::Holidays::DK };
    skip "Date::Holidays::DK not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'dk' ),
        'Testing Date::Holidays::DK' );

    ok( $dh->holidays( year => 2004 ),
        'Testing holidays for Date::Holidays::DK' );
}

SKIP: {
    eval { require Date::Holidays::ES };
    skip "Date::Holidays::ES not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'es' ),
        'Testing Date::Holidays::ES' );

    ok( $dh->holidays( year => 2006 ),
        'Testing holidays with argument for Date::Holidays::ES' );
}

SKIP: {
    eval { require Date::Holidays::FR };
    skip "Date::Holidays::FR not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'fr' ),
        'Testing Date::Holidays::FR' );

    dies_ok { $dh->holidays(); }
        'Testing holidays with no arguments for Date::Holidays::FR';

    dies_ok { $dh->holidays( year => 2017 ); }
        'Testing holidays with argument for Date::Holidays::FR';
}

SKIP: {
    eval { require Date::Holidays::GB };
    skip "Date::Holidays::GB not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'gb' ),
        'Testing Date::Holidays::GB' );

    ok( $dh->holidays(),
        'Testing holidays with no arguments for Date::Holidays::GB' );

    ok( $dh->holidays( year => 2014 ),
        'Testing holidays with argument for Date::Holidays::GB' );
}

SKIP: {
    eval { require Date::Holidays::KR };
    skip "Date::Holidays::KR not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'kr' ),
        'Testing Date::Holidays::KR' );

    dies_ok { $dh->holidays(); }
        'Testing holidays with no arguments for Date::Holidays::KR';

    dies_ok { $dh->holidays( year => 2014 ) }
        'Testing holidays with argument for Date::Holidays::KR';
}

SKIP: {
    eval { require Date::Holidays::NO };
    skip "Date::Holidays::NO not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'no' ),
        'Testing Date::Holidays::NO' );

    ok( $dh->holidays( year => 2004 ),
        'Testing holidays for Date::Holidays::NO' );
}

SKIP: {
    eval { require Date::Holidays::NZ };
    skip "Date::Holidays::NZ not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'nz' ),
        'Testing Date::Holidays::NZ' );

    ok( $dh->holidays( year => 2004 ),
        'Testing holidays for Date::Holidays::NZ' );
}

SKIP: {
    eval { require Date::Holidays::PL };
    skip "Date::Holidays::PL not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'pl' ),
        'Testing Date::Holidays::PL');

    dies_ok { $dh->holidays() }
        'Testing holidays for Date::Holidays::PL';

    dies_ok { $dh->holidays( year => 2004 ) }
        'Testing holidays for Date::Holidays::PL';
}

SKIP: {
    eval { require Date::Holidays::PT };
    skip "Date::Holidays::PT not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'pt' ),
        'Testing Date::Holidays::PT' );

    ok( $dh->holidays( year => 2005 ),
        'Testing holidays for Date::Holidays::PT' );

}

SKIP: {
    eval { require Date::Holidays::RU };
    skip "Date::Holidays::RU not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'ru' ),
        'Testing Date::Holidays::RU' );

    ok( $dh->holidays( year => 2014 ),
        'Testing holidays with argument for Date::Holidays::RU' );
}

SKIP: {
    eval { require Date::Holidays::SK };
    skip "Date::Holidays::SK not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'sk' ),
        'Testing Date::Holidays::SK' );

    ok( $dh->holidays(),
        'Testing holidays without argument for Date::Holidays::SK' );

    ok( $dh->holidays( year => 2014 ),
        'Testing holidays with argument for Date::Holidays::SK' );
}

# TODO: Get UK under control
# SKIP: {
#     eval { require Date::Holidays::UK };
#     skip "Date::Holidays::UK not installed", 3 if $@;

#     ok( $dh = Date::Holidays->new( countrycode => 'uk' ),
#         'Testing Date::Holidays::UK' );

#     use Data::Dumper;
#     print STDERR Dumper $dh;

#     dies_ok { $dh->holidays() }
#         'Testing holidays without argument for Date::Holidays::UK';

#     dies_ok { $dh->holidays( year => 2014 ) }
#         'Testing holidays with argument for Date::Holidays::UK';
# }

SKIP: {
    eval { require Date::Japanese::Holiday };
    skip "Date::Japanese::Holiday not installed", 3 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'jp' ),
        'Testing Date::Japanese::Holiday' );

    dies_ok { $dh->holidays() }
        'Testing holidays without argument for Date::Japanese::Holiday';

    dies_ok { $dh->holidays( year => 2014 ) }
        'Testing holidays with argument for Date::Japanese::Holiday';
}

SKIP: {
    eval { require Date::Holidays::KZ };
    skip "Date::Holidays::KZ not installed", 2 if $@;

    ok( $dh = Date::Holidays->new( countrycode => 'kz' ),
        'Testing Date::Holidays::KZ' );

    ok( $dh->holidays( year => 2018 ),
        'Testing holidays with argument for Date::Holidays::KZ' );
}

done_testing();

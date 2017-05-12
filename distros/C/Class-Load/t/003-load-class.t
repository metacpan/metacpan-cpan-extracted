use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';
use Test::Class::Load ':all';
use Test::Fatal;

is( load_class('Class::Load::OK'), 'Class::Load::OK', 'loaded class OK' );
is( $Class::Load::ERROR, undef, 'ERROR is undef' );

like(
    exception {
        load_class('Class::Load::Nonexistent');
    },
    qr{^Can't locate Class/Load/Nonexistent.pm in \@INC},
    'threw exception for nonexistent class'
);

like(
    $Class::Load::ERROR,
    qr{^Can't locate Class/Load/Nonexistent.pm in \@INC},
    'ERROR message for nonexistent class',
);

ok( load_class('Class::Load::OK'), 'loaded class OK' );
is( $Class::Load::ERROR, undef, 'ERROR is undef' );

like(
    exception {
        load_class('Class::Load::SyntaxError');
    },
    qr{^Missing right curly or square bracket at },
    'exception contains syntax error message'
);

like(
    $Class::Load::ERROR,
    qr{^Missing right curly or square bracket at },
    'ERROR contains syntax error message'
);

ok( is_class_loaded('Class::Load::OK') );
ok( !is_class_loaded('Class::Load::Nonexistent') );
ok( !is_class_loaded('Class::Load::SyntaxError') );

do {

    package Class::Load::Inlined;
    sub inlined { 1 }
};

is(
    load_class('Class::Load::Inlined'),
    'Class::Load::Inlined',
    'loaded class Inlined'
);
is( $Class::Load::ERROR, undef );
ok( is_class_loaded('Class::Load::Inlined') );

like(
    exception {
        load_class( 'Class::Load::VersionCheck', { -version => 43 } );
    },
    qr/^Class::Load::VersionCheck version 43 required/,
    'got expected error for load_class with explicit version'
);

is(
    load_class( 'Class::Load::VersionCheck', { -version => 41 } ),
    'Class::Load::VersionCheck',
    'loaded class with version check'
);

is(
    load_class( 'Class::Load::VersionCheck2', { -version => 41 } ),
    'Class::Load::VersionCheck2',
    'loaded class with version check'
);

like(
    exception {
        load_class( 'Class::Load::VersionCheck2', { -version => 43 } );
    },
    qr/^Class::Load::VersionCheck2 version 43 required/,
    'got expected error for load_class with explicit version (after class has been loaded into memory)'
);

like(
    exception {
        load_class('__PACKAGE__');
    },
    qr/__PACKAGE__\.pm.*\@INC/,
    'errors sanely on __PACKAGE__.pm'
);

done_testing;

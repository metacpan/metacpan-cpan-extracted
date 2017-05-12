use Test::More;
use lib 't/lib';
use NoLang;
use strict;
use File::Spec::Functions;

my $dir;
BEGIN { $dir = catdir qw( t lib ); }

use lib $dir;
use Acme::MetaSyntactic::test_ams_locale;

my @langs = Acme::MetaSyntactic::test_ams_locale->languages();

plan tests => 4 * ( @langs + 2 ) + 7;

is_deeply(
    [ sort @langs ],
    [qw( en fr it x-chiendent yi )],
    "All languages (class)"
);

@langs = Acme::MetaSyntactic::test_ams_locale->new()->languages();
is_deeply(
    [ sort @langs ],
    [qw( en fr it x-chiendent yi )],
    "All languages (instance)"
);

for my $args ( [], map { [ lang => $_ ] } @langs, 'zz' ) {
    my $meta = Acme::MetaSyntactic::test_ams_locale->new(@$args);
    my $lang = $args->[1] || 'fr';
    my ( $one, $four ) = ( 1, 4 );
    $lang = 'fr' if $lang eq 'zz';    # check fallback to default
    my @digits = $meta->name;
    is( $meta->lang, $lang, "lang() is $lang" );
    is( @digits, $one, "Single item ($one $lang)" );
    @digits = $meta->name(4);
    is( @digits, $four, "Four items ($four $lang)" );

    @digits = sort $meta->name(0);
    no warnings;
    my @all = sort @{ $Acme::MetaSyntactic::test_ams_locale::Locale{$lang} };
    is_deeply( \@digits, \@all, "All items ($lang)" );
}

# tests for the various language schemes
# by order of preference LANGUAGE > LANG > Win32::Locale
my $meta;

{
    # we don't need no Windows to test this
    local $INC{"Win32/Locale.pm"} = 1;
    local $^W = 0;
    *Win32::Locale::get_language = sub { 'it' };

    $^O   = 'MSWin32';
    $meta = Acme::MetaSyntactic::test_ams_locale->new;
}

is_deeply( [ sort $meta->name(0) ],
    [ sort @{ $Acme::MetaSyntactic::test_ams_locale::Locale{it} } ], "MSWin32" );

$ENV{LANG} = 'fr';
$meta = Acme::MetaSyntactic::test_ams_locale->new;
is_deeply( [ sort $meta->name(0) ],
    [ sort @{ $Acme::MetaSyntactic::test_ams_locale::Locale{fr} } ], "LANG fr" );

$ENV{LANGUAGE} = 'yi';
$meta = Acme::MetaSyntactic::test_ams_locale->new;
is_deeply( [ sort $meta->name(0) ],
    [ sort @{ $Acme::MetaSyntactic::test_ams_locale::Locale{yi} } ], "LANGUAGE yi" );

delete @ENV{qw( LANG LANGUAGE ) };

$ENV{LANG} = 'x-chiendent';
$meta = Acme::MetaSyntactic::test_ams_locale->new;
is_deeply( [ sort $meta->name(0) ],
    [ sort @{ $Acme::MetaSyntactic::test_ams_locale::Locale{'x-chiendent'} } ],
    "LANG x-chiendent" );

$ENV{LANGUAGE} = 'x-chiendent';
$meta = Acme::MetaSyntactic::test_ams_locale->new;
is_deeply( [ sort $meta->name(0) ],
    [ sort @{ $Acme::MetaSyntactic::test_ams_locale::Locale{'x-chiendent'} } ],
    "LANGUAGE x-chiendent" );


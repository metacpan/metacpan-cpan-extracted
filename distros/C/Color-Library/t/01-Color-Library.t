#use Test::More tests => 1;
use Test::More;

use Color::Library;
my @dictionaries = Color::Library->dictionaries(
    qw/ svg x11 html ie mozilla netscape windows vaccc nbs-iscc /,
    map { "nbs-iscc-$_" } qw/ a b f h m p r rc s sc tc /
);

sub has_color_count( $$ ) {
    my $dictionary = shift;
    my $expect = shift;
    ok( my @colors = $dictionary->colors );
    ok( my @names = $dictionary->names );
    is( @colors, $expect, "$dictionary has $expect colors" );
    is( @names, $expect, "$dictionary has $expect names" );
}

has_color_count( Color::Library->SVG, 148 );
has_color_count( Color::Library->X11, 760 );
has_color_count( Color::Library->HTML, 17 );
has_color_count( Color::Library->IE, 140 );
has_color_count( Color::Library->Mozilla, 146 );
has_color_count( Color::Library->Netscape, 100 );
has_color_count( Color::Library->Windows, 16 );
has_color_count( Color::Library->VACCC, 216 );
has_color_count( Color::Library->Tango, 27 );
has_color_count( Color::Library->NBS_ISCC, 267 );
has_color_count( Color::Library->NBS_ISCC->A, 349 );
has_color_count( Color::Library->NBS_ISCC->B, 788 );
has_color_count( Color::Library->NBS_ISCC->F, 218 );
has_color_count( Color::Library->NBS_ISCC->H, 261 );
has_color_count( Color::Library->NBS_ISCC->M, 4589 );
has_color_count( Color::Library->NBS_ISCC->P, 1623 );
has_color_count( Color::Library->NBS_ISCC->R, 1607 );
has_color_count( Color::Library->NBS_ISCC->RC, 120 );
has_color_count( Color::Library->NBS_ISCC->S, 965 );
has_color_count( Color::Library->NBS_ISCC->SC, 176 );
has_color_count( Color::Library->NBS_ISCC->TC, 268 );

has_color_count( Color::Library::Dictionary::SVG, 148 );
has_color_count( Color::Library::Dictionary::X11, 760 );
has_color_count( Color::Library::Dictionary::HTML, 17 );
has_color_count( Color::Library::Dictionary::IE, 140 );
has_color_count( Color::Library::Dictionary::Mozilla, 146 );
has_color_count( Color::Library::Dictionary::Netscape, 100 );
has_color_count( Color::Library::Dictionary::Windows, 16 );
has_color_count( Color::Library::Dictionary::VACCC, 216 );
has_color_count( Color::Library::Dictionary::Tango, 27 );
has_color_count( Color::Library::Dictionary::NBS_ISCC, 267 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::A, 349 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::B, 788 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::F, 218 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::H, 261 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::M, 4589 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::P, 1623 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::R, 1607 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::RC, 120 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::S, 965 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::SC, 176 );
has_color_count( Color::Library::Dictionary::NBS_ISCC::TC, 268 );

my $seablue = Color::Library->color( "seablue" );
ok( $seablue );
is( "$seablue", "#51585e" );
ok( $seablue->dictionary );
is( $seablue->dictionary->id, "nbs-iscc-f" );
ok( $seablue->value =~ qr/^\d+$/ );
is( ref $seablue->rgb, "ARRAY" );
is( @{ scalar $seablue->rgb }, 3 );

my $grey73 = Color::Library->colour( [qw/ svg x11 /] => "grey73" );
ok( $grey73 );
is( "$grey73", "#bababa" );
is( $grey73->dictionary->id, "x11" );

$seablue = Color::Library->colour( [qw/ svg x11 /] => "seablue" );
ok( !$seablue );

my ( $red, $green, $blue ) = Color::Library->colors(qw/ red x11:green blue /);
ok( $red );
is( $red, "#ff0000" );
is( $red->dictionary->id, "svg" );
ok( $green );
is( $green, "#00ff00" );
is( $green->dictionary->id, "x11" );
ok( $blue );
is( $blue, "#0000ff" );
is( $blue->dictionary->id, "svg" );

my $color = Color::Library->SVG->color( "aliceblue" );
ok( $color );
is( "$color", "#f0f8ff" );
is( $color->dictionary->id, "svg" );

my @names = Color::Library->SVG->names;
ok( @names );
is( @names, 148 );

my @colors = Color::Library->dictionary( 'x11' )->colors;
ok( @colors );
is( @colors, 760 );

done_testing;

#! perl

use Test::More tests => 8;

BEGIN {
	use_ok( 'PDF::API2' );
	use_ok( 'App::PDF::Link::Icons' );
}

my $pdf = PDF::API2->new;
ok( $pdf, "Created PDF" );

App::PDF::Link::Icons::_load_icon_images( {}, $pdf );

my $icons = App::PDF::Link::Icons::__icons();

ok( defined $icons->{mscz}, "Got MuseScore icon" );
ok( defined $icons->{html}, "Got iRealPro icon" );

App::PDF::Link::Icons::_load_icon_images( { all => 1 }, $pdf );

$icons = App::PDF::Link::Icons::__icons();

my $xp = 7 + 23;
ok( keys(%$icons) == $xp, "Got all $xp icons" );

my $i = App::PDF::Link::Icons::get_icon( {}, $pdf, "html" );

ok( $i == $icons->{html}, "Checked HTML icon" );

$i = App::PDF::Link::Icons::get_icon( {}, $pdf, "foo" );

ok( $i == $icons->{" fallback"}, "Checked fallback icon" );

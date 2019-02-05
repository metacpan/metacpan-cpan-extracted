#! perl

use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
	use_ok( 'PDF::API2' );
	use_ok( 'App::PDF::Link::Icons' );
}

my $pdf = PDF::API2->new;
ok( $pdf, "Created PDF" );

App::PDF::Link::Icons::_load_icon_images( {}, $pdf );

my $icons = App::PDF::Link::Icons::__icons();

ok( defined $icons->{mscz}, "Got MuseScore icon" );
ok( defined $icons->{html}, "Got iRealPro icon"  );
ok( defined $icons->{sib},  "Got Sibelius icon"  );
ok( defined $icons->{xml},  "Got MusicXML icon"  );
ok( defined $icons->{abc},  "Got ABC icon"       );

App::PDF::Link::Icons::_load_icon_images( { all => 1 }, $pdf );

$icons = App::PDF::Link::Icons::__icons();

my $xp = 9 + 24;
ok( keys(%$icons) == $xp, "Got all @{[scalar(keys(%$icons))]} icons" );

my $i = App::PDF::Link::Icons::get_icon( {}, $pdf, "html" );

ok( $i == $icons->{html}, "Checked HTML icon" );

$i = App::PDF::Link::Icons::get_icon( {}, $pdf, "foo" );

ok( $i == $icons->{" fallback"}, "Checked fallback icon" );

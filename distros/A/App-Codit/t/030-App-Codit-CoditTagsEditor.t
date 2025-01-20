
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 4;
$mwclass = 'Tk::AppWindow';
require Tk::Font;

BEGIN { use_ok('App::Codit::CoditTagsEditor') };

createapp(
);

my $editor;
if (defined $app) {
	$editor = $app->CoditTagsEditor(
		-extension => $app,
		-defaultbackground => '#FFFFFF',
		-defaultforeground => '#000000',
		-defaultfont => $app->Font(-family => 'Hack', -size => 12),
		-historyfile => 't/color_history',
		-themefile => 'blib/lib/App/Codit/highlight_theme.ctt',
	)->pack(-expand => 1, -fill => 'both');
}

push @tests , [ sub { return defined $editor }, 1, 'CoditTagsEditor created'];


starttesting;


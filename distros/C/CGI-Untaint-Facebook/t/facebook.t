#!perl -wT

use strict;
use Test::Most tests => 17;

BEGIN {
	use_ok('CGI::Untaint::Facebook');
}

FACEBOOK: {
	use_ok('CGI::Untaint');

	my $vars = {
		url1 => 'https://www.facebook.com/rockvillebb',
		url2 => 'http://www.facebook.com/rockvillebb',
		url3 => 'http://www.facebook.com/fru90verfe890vrh89',
		url4 => 'vrjsovdshio',
		url5 => 'ftp://www.facebook.com/voicetimemoney',
		url6 => ' ',
		url7 => 'rockvillebb',
		url8 => 'https://www.facebook.com/people/Green-Mountain-Brass-Band/100063768321239',
		url9 => 'fru90verfe890vrh89',
		url10 => '  rockvillebb ',
		url11 => 'https://www.facebook.com/sandhurstsilverband',
		url12 => 'https://www.facebook.com/KentPolice Band',
		url13 => 'https://www.facebook.com/profile.php?id=100027194451297',
	};

	my $untainter = new_ok('CGI::Untaint' => [ $vars ]);
	my $c = $untainter->extract(-as_Facebook => 'url1');
	ok(defined($c));
	is($c, 'https://www.facebook.com/rockvillebb', 'rockvillebb');

	$c = $untainter->extract(-as_Facebook => 'url2');
	is($c, 'https://www.facebook.com/rockvillebb', 'rockvillebb');

	$c = $untainter->extract(-as_Facebook => 'url3');
	is($c, undef, 'non existent URL');

	$c = $untainter->extract(-as_Facebook => 'url4');
	is($c, undef, 'invalid URL');

	$c = $untainter->extract(-as_Facebook => 'url5');
	is($c, undef, 'using FTP instead of HTTP');

	# and what about empty fields?
	$c = $untainter->extract(-as_Facebook => 'url6');
	is($c, undef, 'Empty');

	$c = $untainter->extract(-as_Facebook => 'url7');
	is($c, 'https://www.facebook.com/rockvillebb', 'rockvillebb');

	$c = $untainter->extract(-as_Facebook => 'url8');
	is($c, 'https://www.facebook.com/people/Green-Mountain-Brass-Band/100063768321239', 'Green Mountain Brass Band');

	$c = $untainter->extract(-as_Facebook => 'url9');
	is($c, undef, 'non existent page');

	$c = $untainter->extract(-as_Facebook => 'url10');
	is($c, 'https://www.facebook.com/rockvillebb', 'leading spaces are ignored');

	$c = $untainter->extract(-as_Facebook => 'url11');
	is($c, 'https://www.facebook.com/sandhurstsilverband', 'Sandhurst');

	$c = $untainter->extract(-as_Facebook => 'url12');
	is($c, undef, 'space in Facebook name');

	$c = $untainter->extract(-as_Facebook => 'url13');
	is($c, 'https://www.facebook.com/profile.php?id=100027194451297', 'Hemel Hempstead');

}

use Test;

#$Id: test.pl,v 1.4 2002/10/23 20:30:46 sherzodr Exp $

use Color::Rgb;

ok(1);

my $rgb = new Color::Rgb(rgb_txt=>'rgb.txt');
ok($rgb);
ok($rgb->rgb('black', ','), '0,0,0');
ok($rgb->rgb('black') );
ok($rgb->hex('black', '#'), '#000000');
ok($rgb->rgb2hex(255,255,255, '#'), '#ffffff');
ok($rgb->rgb2hex(0, 255, 255, '#'), '#00ffff');
ok($rgb->rgb2hex(255,0,255, '#'), '#ff00ff');
ok($rgb->rgb2hex(255,255,0, '#'), '#ffff00');
ok($rgb->hex2rgb('#cccccc', ','), '204,204,204');

ok($rgb->rgb('black', ','), $rgb->name2rgb('black', ',') );

ok($rgb->hex('black', '#'), $rgb->name2hex('black', '#') );

my @names = $rgb->names('grey');

ok(@names);
ok($rgb->names(),  752 );

#print $rgb->dump();

BEGIN { plan tests => 14 };	

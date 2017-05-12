# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Color-Mix.t'
use warnings;

use Test::Warn;
use Test::More tests => 33;
BEGIN { use_ok('Color::Mix') };


####################################################################
#    P u b l i c    m e t h o d s    t e s t
####################################################################

# Create a color
$c = Color::Mix->new;
isa_ok($c,'Color::Mix');

# Create a color from an existing object
$new_c = $c->new;
isa_ok($new_c,'Color::Mix', 'Created from existing object');

# Complementary
$red = 'ff0000';
$green = '00ffff';
ok($c->complementary($red) eq $green, 'Complement of red is green');
ok($c->complementary($green) eq $red, 'Complement of green is red');
ok($c->complementary('red') eq $green, 'Complement of red is green');

# Double Complementary
my $dc1 = [$c->double_complementary('0000ff','ffff00')];
my $dc2 = [qw(ffff00 0000ff)];
is_deeply($dc1,$dc2,'Complements of yellow and blue using RGB is blue and yellow');

# Get hex for color
ok($c->get_color('limegreen') eq '32cd32', 'RGB Hex for limegreen is 32cd32');
ok($c->get_color('black') eq '000000', 'RGB Hex for black is 000000');
ok($c->get_color('white') eq 'ffffff', 'RGB Hex for white is ffffff');

# Lighten a color
ok($c->lighten('black') eq '202020', 'Lighten black name to dark grey');
ok($c->lighten('000000') eq '202020', 'Lighten black hex to dark grey');
ok($c->lighten('000000',2) eq '404040', 'Lighten black hex by 2 is 404040');
ok($c->lighten('000000',3) eq '606060', 'Lighten black hex by 2 is 404040');
ok($c->lighten('white') eq 'ffffff', 'Lighten called on white returns white');

# Set more coarse shades
ok($c->get_shade == 32, 'Default shading value is 32 decimal');
$c->set_shade(64);
ok($c->get_shade == 64, 'Shading value successfully changed to 64 decimal');

ok($c->lighten('000000') eq '404040', 'Lighten black hex to dark grey by 64 incr');
ok($c->lighten('000000',2) eq '808080', 'Lighten black hex to dark grey by 64 incr x 2');
$c->set_shade(32);


# Darken a color
ok($c->darken('white') eq 'dfdfdf', 'Darken called on white name is dfdfdf');
ok($c->darken('ffffff') eq 'dfdfdf', 'Darken called on white hex is dfdfdf');
ok($c->darken('ffffff',2) eq 'bfbfbf', 'Darken called on white by 2 is bfbfbf');
ok($c->darken('ffffff',3) eq '9f9f9f', 'Darken called on white by 2 is 9f9f9f');
ok($c->darken('black') eq '000000', 'Darken called on black should return black');

# Trinary Color
my $tr1 = [$c->trinary('ff0000','3')];
my $tr2 = [qw(ff0000 00ff00 0000ff)];
is_deeply($tr1,$tr2, 'Trinary of red should be red,green,blue');

my $tr3 = [$c->trinary('00ff00','3')];
my $tr4 = [qw(00ff00 0000ff ff0000)];
is_deeply($tr3,$tr4, 'Trinary of green should be green,blue,red');

# Analogous Mixes
my $a1 = [qw(ff0000 ff8000 ffff00 80ff00)];
my $a2 = [$c->analogous('ff0000')];
is_deeply($a1,$a2, 'Analogous Scheme based on red ff0000');

my $a3 = [qw(0000ff 2b00ff 5500ff 8000ff aa00ff d400ff ff00ff)];
my $a4 = [$c->analogous('0000ff', 6, 36)];
is_deeply($a3,$a4, 'Analogous Scheme based on blue to pink - 6 next slices from 36 slice wheel');

my $a5 = [qw(ff0000 00ff00 0000ff)];
my $a6 = [$c->analogous('ff0000', 2, 3)];
is_deeply($a5,$a6, 'Get next two analogous colors from a 3 slice wheel starting at ff0000.');

my $a7 = [qw(ff0000 00ff00 0000ff)];
my $a8 = [$c->analogous('red', 2, 3)];
is_deeply($a7,$a8, 'Get next two analogous colors from a 3 slice wheel starting at red name.');

warning_is {$c->get_color('Homer')} {carped=>q(Doesn't look like a valid color)},
    "Homer is not a valid color";




####################################################################
#    P r i v a t e    m e t h o d s    t e s t
####################################################################
my $resultT = $c->_is_color_name('red');
my $resultF = $c->_is_color_name('homer');
ok($resultT, 'Red is valid color name');
ok((! $resultF), 'Homer isnt valid color name');




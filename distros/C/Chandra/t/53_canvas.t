#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Canvas');

# ========================================================================
# Constructor Tests
# ========================================================================

subtest 'constructor - defaults' => sub {
    my $canvas = Chandra::Canvas->new();
    isa_ok($canvas, 'Chandra::Canvas');
    is($canvas->width, 800, 'default width is 800');
    is($canvas->height, 600, 'default height is 600');
    like($canvas->id, qr/_canvas_\d+/, 'auto-generated id');
};

subtest 'constructor - custom options' => sub {
    my $canvas = Chandra::Canvas->new({
        width  => 1024,
        height => 768,
        id     => 'myCanvas',
    });
    is($canvas->width, 1024, 'custom width');
    is($canvas->height, 768, 'custom height');
    is($canvas->id, 'myCanvas', 'custom id');
};

subtest 'constructor - with style and class' => sub {
    my $canvas = Chandra::Canvas->new({
        width  => 640,
        height => 480,
        style  => 'border: 1px solid black',
        class  => 'game-canvas',
    });
    is($canvas->width, 640, 'width set');
    is($canvas->height, 480, 'height set');
};

# ========================================================================
# Accessor Tests
# ========================================================================

subtest 'accessors - read/write' => sub {
    my $canvas = Chandra::Canvas->new();
    is($canvas->width, 800, 'initial width');
    $canvas->width(1920);
    is($canvas->width, 1920, 'width changed');

    is($canvas->height, 600, 'initial height');
    $canvas->height(1080);
    is($canvas->height, 1080, 'height changed');
};

# ========================================================================
# Method Chaining Tests
# ========================================================================

subtest 'method chaining' => sub {
    my $canvas = Chandra::Canvas->new();

    # Style methods should return self
    my $ret = $canvas->fill_style('#ff0000');
    is($ret, $canvas, 'fill_style returns self');

    $ret = $canvas->stroke_style('#00ff00');
    is($ret, $canvas, 'stroke_style returns self');

    $ret = $canvas->line_width(2);
    is($ret, $canvas, 'line_width returns self');

    $ret = $canvas->global_alpha(0.5);
    is($ret, $canvas, 'global_alpha returns self');

    # Drawing methods should return self
    $ret = $canvas->clear;
    is($ret, $canvas, 'clear returns self');

    $ret = $canvas->fill_rect(0, 0, 100, 100);
    is($ret, $canvas, 'fill_rect returns self');

    $ret = $canvas->stroke_rect(10, 10, 80, 80);
    is($ret, $canvas, 'stroke_rect returns self');

    $ret = $canvas->clear_rect(20, 20, 60, 60);
    is($ret, $canvas, 'clear_rect returns self');

    $ret = $canvas->fill_circle(50, 50, 25);
    is($ret, $canvas, 'fill_circle returns self');

    $ret = $canvas->stroke_circle(50, 50, 30);
    is($ret, $canvas, 'stroke_circle returns self');

    # Path methods should return self
    $ret = $canvas->begin_path;
    is($ret, $canvas, 'begin_path returns self');

    $ret = $canvas->move_to(0, 0);
    is($ret, $canvas, 'move_to returns self');

    $ret = $canvas->line_to(100, 100);
    is($ret, $canvas, 'line_to returns self');

    $ret = $canvas->arc(50, 50, 25, 0, 3.14159);
    is($ret, $canvas, 'arc returns self');

    $ret = $canvas->rect(0, 0, 100, 100);
    is($ret, $canvas, 'rect returns self');

    $ret = $canvas->close_path;
    is($ret, $canvas, 'close_path returns self');

    $ret = $canvas->fill;
    is($ret, $canvas, 'fill returns self');

    $ret = $canvas->stroke;
    is($ret, $canvas, 'stroke returns self');

    # State methods should return self
    $ret = $canvas->save;
    is($ret, $canvas, 'save returns self');

    $ret = $canvas->restore;
    is($ret, $canvas, 'restore returns self');

    # Transform methods should return self
    $ret = $canvas->translate(10, 10);
    is($ret, $canvas, 'translate returns self');

    $ret = $canvas->rotate(0.5);
    is($ret, $canvas, 'rotate returns self');

    $ret = $canvas->scale(2, 2);
    is($ret, $canvas, 'scale returns self');
};

subtest 'fluent API chain' => sub {
    my $canvas = Chandra::Canvas->new();

    # Test a realistic drawing chain
    my $ret = $canvas
        ->clear
        ->fill_style('#ff0000')
        ->fill_rect(0, 0, 100, 100)
        ->fill_style('#00ff00')
        ->fill_rect(100, 0, 100, 100)
        ->fill_style('#0000ff')
        ->fill_rect(200, 0, 100, 100);

    is($ret, $canvas, 'full chain returns self');
};

# ========================================================================
# Command Buffer Tests
# ========================================================================

subtest 'command buffer serialization' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });

    $canvas->fill_style('#ff0000');
    $canvas->fill_rect(10, 20, 100, 50);

    my $js = $canvas->_serialize_buffer;

    like($js, qr/fillStyle/, 'JS contains fillStyle');
    like($js, qr/#ff0000/, 'JS contains color value');
    like($js, qr/fillRect/, 'JS contains fillRect');
    like($js, qr/10/, 'JS contains x coordinate');
    like($js, qr/20/, 'JS contains y coordinate');
    like($js, qr/100/, 'JS contains width');
    like($js, qr/50/, 'JS contains height');
    like($js, qr/testCanvas/, 'JS references canvas id');
};

subtest 'buffer clear' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });

    $canvas->fill_rect(0, 0, 10, 10);
    my $js1 = $canvas->_serialize_buffer;
    like($js1, qr/fillRect/, 'buffer has command');

    $canvas->_clear_buffer;

    my $js2 = $canvas->_serialize_buffer;
    # After clear, only the wrapper should remain, no fillRect
    unlike($js2, qr/fillRect/, 'buffer cleared');
};

subtest 'clear operation' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });

    $canvas->clear;
    my $js = $canvas->_serialize_buffer;

    like($js, qr/clearRect.*canvas\.width.*canvas\.height/, 'clear generates full canvas clearRect');
};

# ========================================================================
# Render Tests
# ========================================================================

subtest 'render HTML' => sub {
    my $canvas = Chandra::Canvas->new({
        id     => 'gameCanvas',
        width  => 800,
        height => 600,
    });

    my $html = $canvas->render;

    like($html, qr/<canvas/, 'HTML starts with canvas tag');
    like($html, qr/id="gameCanvas"/, 'HTML has correct id');
    like($html, qr/width="800"/, 'HTML has correct width');
    like($html, qr/height="600"/, 'HTML has correct height');
    like($html, qr/<\/canvas>/, 'HTML has closing tag');
};

subtest 'render with style and class' => sub {
    my $canvas = Chandra::Canvas->new({
        id     => 'styledCanvas',
        width  => 640,
        height => 480,
        style  => 'border: 1px solid black',
        class  => 'game-canvas',
    });

    my $html = $canvas->render;

    like($html, qr/style="border: 1px solid black"/, 'HTML has style');
    like($html, qr/class="game-canvas"/, 'HTML has class');
};

# ========================================================================
# Multiple Canvas Instances
# ========================================================================

subtest 'multiple instances' => sub {
    my $canvas1 = Chandra::Canvas->new({ width => 100, height => 100 });
    my $canvas2 = Chandra::Canvas->new({ width => 200, height => 200 });

    isnt($canvas1->id, $canvas2->id, 'different instances have different ids');
    is($canvas1->width, 100, 'canvas1 has correct width');
    is($canvas2->width, 200, 'canvas2 has correct width');

    # Drawing on one shouldn't affect the other
    $canvas1->fill_style('#f00');
    $canvas2->fill_style('#0f0');

    my $js1 = $canvas1->_serialize_buffer;
    my $js2 = $canvas2->_serialize_buffer;

    like($js1, qr/#f00/, 'canvas1 has red');
    unlike($js1, qr/#0f0/, 'canvas1 does not have green');

    like($js2, qr/#0f0/, 'canvas2 has green');
    unlike($js2, qr/#f00/, 'canvas2 does not have red');
};

done_testing();

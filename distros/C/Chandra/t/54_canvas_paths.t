#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Canvas');

# ========================================================================
# Phase 2: Path API and Transforms Tests
# ========================================================================

# ========================================================================
# Bezier Curve Method Chaining
# ========================================================================

subtest 'bezier_curve_to returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->begin_path
                     ->move_to(50, 50)
                     ->bezier_curve_to(100, 0, 150, 100, 200, 50);
    is($ret, $canvas, 'bezier_curve_to returns self');
};

subtest 'quadratic_curve_to returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->begin_path
                     ->move_to(50, 50)
                     ->quadratic_curve_to(100, 0, 150, 50);
    is($ret, $canvas, 'quadratic_curve_to returns self');
};

subtest 'arc_to returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->begin_path
                     ->move_to(50, 50)
                     ->arc_to(100, 50, 100, 100, 20);
    is($ret, $canvas, 'arc_to returns self');
};

# ========================================================================
# Clipping Tests
# ========================================================================

subtest 'clip returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->begin_path
                     ->rect(50, 50, 100, 100)
                     ->clip;
    is($ret, $canvas, 'clip returns self');
};

# ========================================================================
# Transform Method Chaining
# ========================================================================

subtest 'transform returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->transform(1, 0.5, 0.5, 1, 0, 0);
    is($ret, $canvas, 'transform returns self');
};

subtest 'set_transform returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->set_transform(1, 0, 0, 1, 0, 0);
    is($ret, $canvas, 'set_transform returns self');
};

subtest 'reset_transform returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->reset_transform;
    is($ret, $canvas, 'reset_transform returns self');
};

# ========================================================================
# Style Method Chaining
# ========================================================================

subtest 'miter_limit returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->miter_limit(10);
    is($ret, $canvas, 'miter_limit returns self');
};

subtest 'global_composite_operation returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->global_composite_operation('source-over');
    is($ret, $canvas, 'global_composite_operation returns self');
};

# ========================================================================
# Convenience Shape Methods
# ========================================================================

subtest 'line returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->line(10, 10, 100, 100);
    is($ret, $canvas, 'line returns self');
};

subtest 'polygon returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->polygon([[50, 0], [100, 50], [50, 100], [0, 50]]);
    is($ret, $canvas, 'polygon returns self');
};

subtest 'fill_polygon returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->fill_polygon([[50, 0], [100, 50], [50, 100], [0, 50]]);
    is($ret, $canvas, 'fill_polygon returns self');
};

subtest 'rounded_rect returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->rounded_rect(10, 10, 100, 50, 10);
    is($ret, $canvas, 'rounded_rect returns self');
};

subtest 'fill_rounded_rect returns self' => sub {
    my $canvas = Chandra::Canvas->new();
    my $ret = $canvas->fill_rounded_rect(10, 10, 100, 50, 10);
    is($ret, $canvas, 'fill_rounded_rect returns self');
};

# ========================================================================
# JS Generation Tests
# ========================================================================

subtest 'bezier_curve_to generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->begin_path
           ->move_to(50, 50)
           ->bezier_curve_to(100, 0, 150, 100, 200, 50)
           ->stroke;
    my $js = $canvas->_serialize_buffer;
    like($js, qr/bezierCurveTo\s*\(\s*100\s*,\s*0\s*,\s*150\s*,\s*100\s*,\s*200\s*,\s*50\s*\)/,
         'bezierCurveTo generates correct JS');
};

subtest 'quadratic_curve_to generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->begin_path
           ->move_to(50, 50)
           ->quadratic_curve_to(100, 0, 150, 50)
           ->stroke;
    my $js = $canvas->_serialize_buffer;
    like($js, qr/quadraticCurveTo\s*\(\s*100\s*,\s*0\s*,\s*150\s*,\s*50\s*\)/,
         'quadraticCurveTo generates correct JS');
};

subtest 'arc_to generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->begin_path
           ->move_to(50, 50)
           ->arc_to(100, 50, 100, 100, 20)
           ->stroke;
    my $js = $canvas->_serialize_buffer;
    like($js, qr/arcTo\s*\(\s*100\s*,\s*50\s*,\s*100\s*,\s*100\s*,\s*20\s*\)/,
         'arcTo generates correct JS');
};

subtest 'clip generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->begin_path
           ->rect(50, 50, 100, 100)
           ->clip;
    my $js = $canvas->_serialize_buffer;
    like($js, qr/clip\s*\(\s*\)/, 'clip generates correct JS');
};

subtest 'transform generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->transform(1, 0.5, 0.5, 1, 0, 0);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/transform\s*\(\s*1\s*,\s*0\.5\s*,\s*0\.5\s*,\s*1\s*,\s*0\s*,\s*0\s*\)/,
         'transform generates correct JS');
};

subtest 'set_transform generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->set_transform(1, 0, 0, 1, 10, 20);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/setTransform\s*\(\s*1\s*,\s*0\s*,\s*0\s*,\s*1\s*,\s*10\s*,\s*20\s*\)/,
         'setTransform generates correct JS');
};

subtest 'reset_transform generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->reset_transform;
    my $js = $canvas->_serialize_buffer;
    like($js, qr/resetTransform\s*\(\s*\)/, 'resetTransform generates correct JS');
};

subtest 'miter_limit generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->miter_limit(15);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/miterLimit\s*=\s*15/, 'miterLimit generates correct JS');
};

subtest 'global_composite_operation generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->global_composite_operation('lighter');
    my $js = $canvas->_serialize_buffer;
    like($js, qr/globalCompositeOperation\s*=\s*['"]lighter['"]/, 
         'globalCompositeOperation generates correct JS');
};

subtest 'line generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->line(10, 20, 100, 200);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/beginPath/, 'line starts path');
    like($js, qr/moveTo\s*\(\s*10\s*,\s*20\s*\)/, 'line moves to start');
    like($js, qr/lineTo\s*\(\s*100\s*,\s*200\s*\)/, 'line draws to end');
    like($js, qr/stroke/, 'line strokes');
};

subtest 'rounded_rect generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->rounded_rect(10, 20, 100, 50, 10);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/roundRect\s*\(\s*10\s*,\s*20\s*,\s*100\s*,\s*50\s*,\s*10\s*\)/,
         'roundRect generates correct JS');
    like($js, qr/stroke/, 'rounded_rect strokes');
};

subtest 'fill_rounded_rect generates correct JS' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    $canvas->fill_rounded_rect(10, 20, 100, 50, 10);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/roundRect\s*\(\s*10\s*,\s*20\s*,\s*100\s*,\s*50\s*,\s*10\s*\)/,
         'fill_rounded_rect generates correct JS');
    like($js, qr/fill/, 'fill_rounded_rect fills');
};

# ========================================================================
# Fluent API Integration Tests
# ========================================================================

subtest 'complete path drawing chain' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    
    my $ret = $canvas
        ->save
        ->fill_style('#ff0000')
        ->begin_path
        ->move_to(100, 100)
        ->bezier_curve_to(150, 50, 200, 150, 250, 100)
        ->quadratic_curve_to(300, 50, 350, 100)
        ->arc_to(400, 100, 400, 150, 25)
        ->line_to(400, 200)
        ->close_path
        ->fill
        ->restore;
    
    is($ret, $canvas, 'complete bezier/arc path chain returns self');
    
    my $js = $canvas->_serialize_buffer;
    like($js, qr/bezierCurveTo/, 'JS contains bezierCurveTo');
    like($js, qr/quadraticCurveTo/, 'JS contains quadraticCurveTo');
    like($js, qr/arcTo/, 'JS contains arcTo');
};

subtest 'transform chain' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    
    my $ret = $canvas
        ->save
        ->translate(100, 100)
        ->rotate(0.5)
        ->scale(2, 2)
        ->transform(1, 0, 0, 1, 10, 10)
        ->fill_rect(0, 0, 50, 50)
        ->reset_transform
        ->restore;
    
    is($ret, $canvas, 'transform chain returns self');
    
    my $js = $canvas->_serialize_buffer;
    like($js, qr/translate/, 'JS contains translate');
    like($js, qr/rotate/, 'JS contains rotate');
    like($js, qr/scale/, 'JS contains scale');
    like($js, qr/transform\(/, 'JS contains transform');
    like($js, qr/resetTransform/, 'JS contains resetTransform');
};

subtest 'clipping region drawing' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    
    my $ret = $canvas
        ->save
        ->begin_path
        ->arc(100, 100, 50, 0, 6.28)
        ->clip
        ->fill_style('#ff0000')
        ->fill_rect(50, 50, 100, 100)
        ->restore;
    
    is($ret, $canvas, 'clip region chain returns self');
    
    my $js = $canvas->_serialize_buffer;
    like($js, qr/clip\(\)/, 'JS contains clip');
};

subtest 'convenience shapes chain' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    
    my $ret = $canvas
        ->stroke_style('#000000')
        ->line_width(2)
        ->line(10, 10, 100, 100)
        ->fill_style('#ff0000')
        ->fill_polygon([[150, 50], [200, 100], [150, 150], [100, 100]])
        ->stroke_style('#00ff00')
        ->polygon([[250, 50], [300, 100], [250, 150], [200, 100]])
        ->fill_style('#0000ff')
        ->fill_rounded_rect(50, 200, 100, 50, 10)
        ->stroke_style('#000000')
        ->rounded_rect(200, 200, 100, 50, 15);
    
    is($ret, $canvas, 'convenience shapes chain returns self');
    
    my $js = $canvas->_serialize_buffer;
    like($js, qr/moveTo.*lineTo.*stroke/s, 'line generates path operations');
    like($js, qr/roundRect/, 'rounded rect operations present');
};

subtest 'compositing modes' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    
    my $ret = $canvas
        ->fill_style('#ff0000')
        ->fill_rect(50, 50, 100, 100)
        ->global_composite_operation('lighter')
        ->fill_style('#00ff00')
        ->fill_rect(100, 100, 100, 100)
        ->global_composite_operation('source-over');
    
    is($ret, $canvas, 'compositing chain returns self');
    
    my $js = $canvas->_serialize_buffer;
    like($js, qr/globalCompositeOperation\s*=\s*['"]lighter['"]/, 'lighter mode set');
    like($js, qr/globalCompositeOperation\s*=\s*['"]source-over['"]/, 'source-over mode set');
};

# ========================================================================
# Polygon Point Handling Tests
# ========================================================================

subtest 'polygon with minimum points' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    # Triangle - minimum polygon
    $canvas->polygon([[0, 0], [50, 100], [100, 0]]);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/moveTo/, 'polygon starts with moveTo');
    like($js, qr/lineTo/, 'polygon has lineTo');
    like($js, qr/closePath/, 'polygon closes path');
};

subtest 'fill_polygon with many points' => sub {
    my $canvas = Chandra::Canvas->new({ id => 'testCanvas' });
    # Hexagon
    $canvas->fill_polygon([
        [50, 0],    # top
        [100, 25],  # top-right
        [100, 75],  # bottom-right
        [50, 100],  # bottom
        [0, 75],    # bottom-left
        [0, 25]     # top-left
    ]);
    my $js = $canvas->_serialize_buffer;
    like($js, qr/fill\(\)/, 'fill_polygon fills');
    # Count lineTo calls (should be 5 for hexagon - first point is moveTo)
    my @lineTo_matches = ($js =~ /lineTo/g);
    is(scalar(@lineTo_matches), 5, 'hexagon has correct number of lineTo calls');
};

done_testing();

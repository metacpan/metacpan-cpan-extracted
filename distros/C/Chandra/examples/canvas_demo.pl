#!/usr/bin/env perl
# ============================================================================
# Chandra::Canvas Interactive Demo
# ============================================================================
# A working UI application demonstrating all Chandra::Canvas features.
# Features an interactive drawing canvas with shape selection, color picker,
# and real-time drawing using Perl callbacks.
#
# Run with: perl examples/canvas_demo.pl
# ============================================================================

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

use Chandra::App;
use Chandra::Canvas;

# ============================================================================
# Create the application
# ============================================================================
my $app = Chandra::App->new(
    title  => 'Chandra::Canvas Demo',
    width  => 900,
    height => 700,
    debug  => 1,
);

# ============================================================================
# Create the canvas
# ============================================================================
my $canvas = Chandra::Canvas->new({
    width  => 800,
    height => 500,
    id     => 'mainCanvas',
});

# State
my $current_color = '#e74c3c';
my $current_shape = 'rect';
my $line_width = 3;

# Helper to flush canvas via app's dispatch_eval
sub canvas_flush {
    my $js = $canvas->_serialize_buffer;
    $app->dispatch_eval($js);
    $canvas->_clear_buffer;
}

# ============================================================================
# Bind Perl functions for JS to call
# ============================================================================

# Draw a shape at the given position
$app->bind('draw_shape', sub {
    my ($x, $y, $shape, $color, $size) = @_;
    $size //= 40;
    
    $canvas->fill_style($color)
           ->stroke_style('#2c3e50')
           ->line_width(2);
    
    if ($shape eq 'rect') {
        $canvas->fill_rect($x - $size/2, $y - $size/2, $size, $size)
               ->stroke_rect($x - $size/2, $y - $size/2, $size, $size);
    }
    elsif ($shape eq 'circle') {
        $canvas->fill_circle($x, $y, $size/2)
               ->stroke_circle($x, $y, $size/2);
    }
    elsif ($shape eq 'triangle') {
        $canvas->begin_path
               ->move_to($x, $y - $size/2)
               ->line_to($x + $size/2, $y + $size/2)
               ->line_to($x - $size/2, $y + $size/2)
               ->close_path
               ->fill
               ->stroke;
    }
    elsif ($shape eq 'star') {
        my @points;
        for my $i (0..9) {
            my $r = ($i % 2 == 0) ? $size/2 : $size/4;
            my $angle = ($i * 3.14159 / 5) - 3.14159/2;
            push @points, [$x + $r * cos($angle), $y + $r * sin($angle)];
        }
        $canvas->fill_polygon(\@points);
    }
    elsif ($shape eq 'rounded_rect') {
        $canvas->fill_rounded_rect($x - $size/2, $y - $size/3, $size, $size*2/3, 10)
               ->stroke_style('#2c3e50')
               ->rounded_rect($x - $size/2, $y - $size/3, $size, $size*2/3, 10);
    }
    elsif ($shape eq 'bezier') {
        $canvas->stroke_style($color)
               ->line_width(4)
               ->begin_path
               ->move_to($x - $size, $y)
               ->bezier_curve_to($x - $size/2, $y - $size, $x + $size/2, $y + $size, $x + $size, $y)
               ->stroke;
    }
    
    # Flush drawing commands to the canvas
    canvas_flush();
    
    return "Drew $shape at ($x, $y)";
});

# Clear the canvas
$app->bind('clear_canvas', sub {
    $canvas->clear;
    canvas_flush();
    return "Canvas cleared";
});

# Draw the demo scene showing all features
$app->bind('draw_demo', sub {
    $canvas->clear;
    
    # Title
    $canvas->fill_style('#2c3e50');
    
    # Row 1: Basic Shapes
    $canvas->fill_style('#e74c3c')->fill_rect(50, 30, 60, 60);
    $canvas->fill_style('#3498db')->fill_circle(180, 60, 30);
    $canvas->fill_style('#27ae60')
           ->begin_path->move_to(280, 30)->line_to(320, 90)->line_to(240, 90)->close_path->fill;
    $canvas->fill_style('#9b59b6')
           ->begin_path->arc(400, 60, 30, 0, 3.14159)->fill;
    $canvas->fill_style('#f39c12')->fill_rounded_rect(470, 30, 80, 60, 12);
    $canvas->fill_style('#1abc9c')
           ->fill_polygon([[620, 30], [660, 50], [650, 90], [590, 90], [580, 50]]);
    
    # Row 2: Bezier Curves
    $canvas->stroke_style('#e74c3c')->line_width(3)
           ->begin_path->move_to(50, 150)->bezier_curve_to(100, 100, 200, 200, 250, 150)->stroke;
    $canvas->stroke_style('#3498db')
           ->begin_path->move_to(280, 150)->quadratic_curve_to(350, 100, 420, 150)->stroke;
    $canvas->stroke_style('#27ae60')
           ->begin_path->move_to(450, 180)->line_to(500, 130)->arc_to(550, 130, 550, 180, 20)->line_to(550, 180)->stroke;
    
    # Row 3: Transforms
    $canvas->save->translate(100, 280)->fill_style('#e67e22')->fill_rect(-30, -30, 60, 60)->restore;
    $canvas->save->translate(220, 280)->rotate(0.785)->fill_style('#8e44ad')->fill_rect(-30, -30, 60, 60)->restore;
    $canvas->save->translate(340, 280)->scale(1.5, 0.7)->fill_style('#16a085')->fill_rect(-30, -30, 60, 60)->restore;
    $canvas->save->translate(460, 280)->transform(1, 0.3, 0.3, 1, 0, 0)->fill_style('#2980b9')->fill_rect(-30, -30, 60, 60)->restore;
    
    # Row 4: Clipping
    $canvas->save
           ->begin_path->arc(620, 280, 40, 0, 6.283)->clip
           ->fill_style('#c0392b')->fill_rect(580, 240, 80, 80)
           ->fill_style('#f1c40f')->fill_rect(600, 260, 80, 80)
           ->restore;
    
    # Row 5: Lines & Polygons
    $canvas->stroke_style('#34495e')->line_width(3)->line(50, 380, 150, 430);
    $canvas->stroke_style('#16a085')->polygon([[220, 380], [280, 380], [300, 430], [250, 460], [200, 430]]);
    $canvas->fill_style('#d35400')
           ->fill_polygon([[400, 370], [420, 410], [470, 410], [430, 440], [450, 480], [400, 450], [350, 480], [370, 440], [330, 410], [380, 410]]);
    
    # Row 6: Compositing
    $canvas->fill_style('#3498db')->fill_rect(550, 380, 60, 60);
    $canvas->global_composite_operation('lighter')
           ->fill_style('#e74c3c')->fill_rect(580, 400, 60, 60)
           ->global_composite_operation('source-over');
    $canvas->fill_style('#27ae60')->fill_rect(680, 380, 60, 60);
    $canvas->global_composite_operation('multiply')
           ->fill_style('#f39c12')->fill_rect(700, 400, 60, 60)
           ->global_composite_operation('source-over');
    
    canvas_flush();
    return "Demo scene drawn";
});

# ============================================================================
# Build the UI
# ============================================================================
my $canvas_html = $canvas->render;

$app->set_content(<<"HTML");
<!DOCTYPE html>
<html>
<head>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
        min-height: 100vh;
        padding: 20px;
        color: #fff;
    }
    .container {
        max-width: 860px;
        margin: 0 auto;
    }
    h1 {
        text-align: center;
        margin-bottom: 20px;
        font-size: 24px;
        color: #f1f1f1;
    }
    .canvas-wrapper {
        background: #fff;
        border-radius: 12px;
        padding: 10px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        margin-bottom: 20px;
    }
    canvas {
        display: block;
        border-radius: 8px;
        cursor: crosshair;
    }
    .toolbar {
        display: flex;
        gap: 15px;
        flex-wrap: wrap;
        justify-content: center;
        margin-bottom: 15px;
    }
    .tool-group {
        background: rgba(255,255,255,0.1);
        border-radius: 8px;
        padding: 10px 15px;
        display: flex;
        gap: 8px;
        align-items: center;
    }
    .tool-group label {
        font-size: 12px;
        color: #aaa;
        margin-right: 5px;
    }
    button {
        background: #3498db;
        color: #fff;
        border: none;
        padding: 8px 16px;
        border-radius: 6px;
        cursor: pointer;
        font-size: 13px;
        transition: all 0.2s;
    }
    button:hover {
        background: #2980b9;
        transform: translateY(-1px);
    }
    button.active {
        background: #e74c3c;
    }
    button.clear {
        background: #95a5a6;
    }
    button.clear:hover {
        background: #7f8c8d;
    }
    button.demo {
        background: #27ae60;
    }
    button.demo:hover {
        background: #219a52;
    }
    .color-btn {
        width: 28px;
        height: 28px;
        border-radius: 50%;
        border: 2px solid transparent;
        cursor: pointer;
        transition: all 0.2s;
    }
    .color-btn:hover {
        transform: scale(1.1);
    }
    .color-btn.active {
        border-color: #fff;
        box-shadow: 0 0 10px rgba(255,255,255,0.5);
    }
    .status {
        text-align: center;
        font-size: 12px;
        color: #888;
        margin-top: 10px;
    }
    .features {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 10px;
        margin-top: 15px;
        font-size: 11px;
        color: #888;
    }
    .feature {
        background: rgba(255,255,255,0.05);
        padding: 8px;
        border-radius: 6px;
        text-align: center;
    }
</style>
</head>
<body>
<div class="container">
    <h1>🎨 Chandra::Canvas Demo</h1>
    
    <div class="toolbar">
        <div class="tool-group">
            <label>Shape:</label>
            <button id="btn-rect" class="active" onclick="setShape('rect')">▢ Rect</button>
            <button id="btn-circle" onclick="setShape('circle')">○ Circle</button>
            <button id="btn-triangle" onclick="setShape('triangle')">△ Triangle</button>
            <button id="btn-star" onclick="setShape('star')">★ Star</button>
            <button id="btn-rounded_rect" onclick="setShape('rounded_rect')">▢ Rounded</button>
            <button id="btn-bezier" onclick="setShape('bezier')">〰 Bezier</button>
        </div>
        
        <div class="tool-group">
            <label>Color:</label>
            <div class="color-btn active" style="background:#e74c3c" onclick="setColor('#e74c3c')"></div>
            <div class="color-btn" style="background:#3498db" onclick="setColor('#3498db')"></div>
            <div class="color-btn" style="background:#27ae60" onclick="setColor('#27ae60')"></div>
            <div class="color-btn" style="background:#f39c12" onclick="setColor('#f39c12')"></div>
            <div class="color-btn" style="background:#9b59b6" onclick="setColor('#9b59b6')"></div>
            <div class="color-btn" style="background:#1abc9c" onclick="setColor('#1abc9c')"></div>
        </div>
        
        <div class="tool-group">
            <button class="demo" onclick="drawDemo()">✨ Show All Features</button>
            <button class="clear" onclick="clearCanvas()">🗑 Clear</button>
        </div>
    </div>
    
    <div class="canvas-wrapper">
        $canvas_html
    </div>
    
    <div class="status" id="status">Click on canvas to draw shapes</div>
    
    <div class="features">
        <div class="feature">📦 Rectangles & Circles</div>
        <div class="feature">📐 Paths & Polygons</div>
        <div class="feature">🔄 Transforms</div>
        <div class="feature">✂️ Clipping Regions</div>
        <div class="feature">〰️ Bezier Curves</div>
        <div class="feature">🎭 Compositing</div>
    </div>
</div>

<script>
    let currentShape = 'rect';
    let currentColor = '#e74c3c';
    let shapeSize = 50;
    
    const canvas = document.getElementById('mainCanvas');
    
    canvas.addEventListener('click', async (e) => {
        const rect = canvas.getBoundingClientRect();
        const x = Math.round(e.clientX - rect.left);
        const y = Math.round(e.clientY - rect.top);
        
        const result = await window.chandra.invoke('draw_shape', [x, y, currentShape, currentColor, shapeSize]);
        document.getElementById('status').textContent = result;
    });
    
    canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        shapeSize = Math.max(20, Math.min(100, shapeSize - e.deltaY / 10));
        document.getElementById('status').textContent = 'Shape size: ' + Math.round(shapeSize);
    });
    
    function setShape(shape) {
        currentShape = shape;
        document.querySelectorAll('.tool-group button').forEach(b => {
            if (b.id && b.id.startsWith('btn-')) b.classList.remove('active');
        });
        document.getElementById('btn-' + shape).classList.add('active');
        document.getElementById('status').textContent = 'Selected: ' + shape;
    }
    
    function setColor(color) {
        currentColor = color;
        document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
        event.target.classList.add('active');
    }
    
    async function clearCanvas() {
        const result = await window.chandra.invoke('clear_canvas', []);
        document.getElementById('status').textContent = result;
    }
    
    async function drawDemo() {
        document.getElementById('status').textContent = 'Drawing demo...';
        const result = await window.chandra.invoke('draw_demo', []);
        document.getElementById('status').textContent = result + ' - Click to draw more!';
    }
    
    // Draw initial demo
    drawDemo();
</script>
</body>
</html>
HTML

print "Starting Chandra::Canvas Demo...\n";
print "Click on canvas to draw shapes!\n";
print "Use mouse wheel to change shape size.\n";

$app->run;

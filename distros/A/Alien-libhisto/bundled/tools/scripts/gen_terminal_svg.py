#!/usr/bin/env python3
"""
gen_terminal_svg.py - Generate high-resolution, pixel-perfect dark mode terminal window SVGs for libhisto docs.
"""

import os
import math

def viridis(t):
    """Return hex color for t in [0, 1] following Viridis colormap."""
    t = max(0.0, min(1.0, t))
    # Viridis polynomial approximation
    r = int(255 * (0.267 + 0.005 * t + 0.322 * t**2 + 0.406 * t**3))
    g = int(255 * (0.004 + 0.900 * t - 0.285 * t**2 + 0.381 * t**3))
    b = int(255 * (0.329 + 1.250 * t - 1.680 * t**2 + 0.091 * t**3))
    # Accurate sample points
    colors = [
        (68, 1, 84),     # 0.0 - dark purple
        (72, 35, 116),   # 0.15
        (64, 67, 135),   # 0.25
        (52, 94, 141),   # 0.35
        (41, 120, 142),  # 0.45 - teal
        (32, 144, 140),  # 0.55
        (34, 168, 132),  # 0.65 - green
        (68, 190, 112),  # 0.75
        (121, 209, 81),  # 0.85
        (189, 223, 38),  # 0.95 - yellow-green
        (253, 231, 37),  # 1.0 - bright yellow
    ]
    idx = t * (len(colors) - 1)
    i0 = int(idx)
    i1 = min(i0 + 1, len(colors) - 1)
    f = idx - i0
    r = int(colors[i0][0] * (1 - f) + colors[i1][0] * f)
    g = int(colors[i0][1] * (1 - f) + colors[i1][1] * f)
    b = int(colors[i0][2] * (1 - f) + colors[i1][2] * f)
    return f"#{r:02x}{g:02x}{b:02x}"

def generate_1d_svg(output_path):
    # Simulated Gaussian histogram data
    bins = [
        ("[  0.00,   4.00)", 63, 1),
        ("[  4.00,   8.00)", 151, 2),
        ("[  8.00,  12.00)", 314, 3),
        ("[ 12.00,  16.00)", 593, 5),
        ("[ 16.00,  20.00)", 1111, 9),
        ("[ 20.00,  24.00)", 1901, 15),
        ("[ 24.00,  28.00)", 2929, 23),
        ("[ 28.00,  32.00)", 4410, 35),
        ("[ 32.00,  36.00)", 6002, 48),
        ("[ 36.00,  40.00)", 7787, 62),
        ("[ 40.00,  44.00)", 9213, 73),
        ("[ 44.00,  48.00)", 10301, 82),
        ("[ 48.00,  52.00)", 10546, 84),
        ("[ 52.00,  56.00)", 10278, 82),
        ("[ 56.00,  60.00)", 9277, 74),
        ("[ 60.00,  64.00)", 7656, 61),
        ("[ 64.00,  68.00)", 6007, 48),
        ("[ 68.00,  72.00)", 4313, 34),
        ("[ 72.00,  76.00)", 2943, 23),
        ("[ 76.00,  80.00)", 1892, 15),
        ("[ 80.00,  84.00)", 1059, 8),
        ("[ 84.00,  88.00)", 655, 5),
        ("[ 88.00,  92.00)", 300, 2),
        ("[ 92.00,  96.00)", 149, 1),
        ("[ 96.00, 100.00)", 69, 1),
    ]
    max_count = 10546

    width = 820
    row_height = 20
    header_rows = 7
    total_rows = len(bins) + header_rows + 2
    height = 50 + total_rows * row_height

    svg = []
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="100%" height="auto">')
    svg.append('<defs>')
    svg.append('''  <style>
    .window { fill: #0d1117; stroke: #30363d; stroke-width: 1px; rx: 10px; }
    .titlebar { fill: #161b22; }
    .title-text { fill: #8b949e; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace; font-size: 12px; font-weight: 600; text-anchor: middle; }
    .term-text { font-family: "SF Mono", Monaco, "Cascadia Code", "Liberation Mono", Menlo, Consolas, monospace; font-size: 13px; fill: #c9d1d9; }
    .cmd-prompt { fill: #58a6ff; font-weight: bold; }
    .cmd-text { fill: #e6edf3; }
    .stat-box { fill: #161b22; stroke: #30363d; stroke-width: 1px; rx: 4px; }
    .stat-label { fill: #8b949e; }
    .stat-val { fill: #58a6ff; font-weight: bold; }
    .bin-edge { fill: #8b949e; }
    .bin-count { fill: #79c0ff; text-anchor: end; font-weight: 500; }
    .summary-text { fill: #8b949e; font-size: 12px; }
  </style>''')
    svg.append('</defs>')

    # Terminal Window Box with Shadow
    svg.append(f'  <rect class="window" x="1" y="1" width="{width-2}" height="{height-2}" />')
    # Title Bar
    svg.append(f'  <path class="titlebar" d="M1,10 Q1,1 10,1 L{width-10},1 Q{width-1},1 {width-1},10 L{width-1},36 L1,36 Z" />')
    # Window Buttons
    svg.append('  <circle cx="20" cy="18" r="6" fill="#ff5f56" />')
    svg.append('  <circle cx="40" cy="18" r="6" fill="#ffbd2e" />')
    svg.append('  <circle cx="60" cy="18" r="6" fill="#27c93f" />')
    # Title text
    svg.append(f'  <text class="title-text" x="{width//2}" y="22">histo plot — Gaussian Monte Carlo (N=100k, μ=50, σ=15)</text>')

    # Terminal Content
    y = 62
    # Prompt Command
    svg.append(f'  <text class="term-text" x="24" y="{y}"><tspan class="cmd-prompt">$ </tspan><tspan class="cmd-text">python3 -c &quot;...&quot; | histo fill --bins=25 --min=0 --max=100 | histo plot --color=always</tspan></text>')
    y += 24

    # Header title
    svg.append(f'  <text class="term-text" x="24" y="{y}" font-weight="bold" fill="#f0883e">Gaussian Monte Carlo (N=100k, μ=50, σ=15) <tspan fill="#8b949e" font-weight="normal">(Entries: 99919, Weight: 99919.0)</tspan></text>')
    y += 18

    # Stats Box
    svg.append(f'  <rect class="stat-box" x="24" y="{y}" width="{width-48}" height="26" />')
    stat_str = '<tspan class="stat-label">Mean: </tspan><tspan class="stat-val">49.97</tspan>   │   <tspan class="stat-label">StdDev: </tspan><tspan class="stat-val">14.96</tspan>   │   <tspan class="stat-label">Median: </tspan><tspan class="stat-val">49.97</tspan>   │   <tspan class="stat-label">IQR: </tspan><tspan class="stat-val">20.18</tspan>   │   <tspan class="stat-label">Mode: </tspan><tspan class="stat-val">49.91</tspan>'
    svg.append(f'  <text class="term-text" x="36" y="{y+18}">{stat_str}</text>')
    y += 36

    # Bars
    bar_start_x = 240
    max_bar_width = width - bar_start_x - 30

    for edge, count, _ in bins:
        t = count / max_count
        color = viridis(t)
        bar_len = int(t * max_bar_width)
        err = math.sqrt(count)

        # Edge label
        svg.append(f'  <text class="term-text bin-edge" x="24" y="{y}">{edge} │</text>')
        # Count label
        svg.append(f'  <text class="term-text bin-count" x="225" y="{y}">{count:,}</text>')
        svg.append(f'  <text class="term-text bin-edge" x="232" y="{y}">│</text>')

        # Colored Histogram Bar
        if bar_len > 0:
            svg.append(f'  <rect x="{bar_start_x}" y="{y-12}" width="{bar_len}" height="14" rx="2" fill="{color}" />')

        # Error bar whisker
        err_x = bar_start_x + bar_len + 8
        if err_x + 60 < width - 10:
            svg.append(f'  <text class="term-text" x="{err_x}" y="{y}" fill="#6e7681" font-size="11px">╎±{err:.1f}╎</text>')

        y += row_height

    # Footer
    y += 6
    footer = 'Underflow: 36  │  In-Range: 99,919  │  Overflow: 45  │  Non-Finite/NaN: 0'
    svg.append(f'  <text class="term-text summary-text" x="24" y="{y}">{footer}</text>')

    svg.append('</svg>')

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(svg) + "\n")
    print(f"Generated SVG at {output_path}")

if __name__ == "__main__":
    generate_1d_svg("docs/assets/demo_terminal_1d.svg")

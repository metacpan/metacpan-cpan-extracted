set terminal postscript enhanced color
set output "temp.ps"
set xtics font "arial,18" textcolor rgb "magenta"
set format x "%.1g"
set y2tics scale 4,2
set my2tics 5
set x2tics (-8,-6,-2,2,5,9)
set ytics nomirror rotate by 30 (-0.8,0.3,0.6)

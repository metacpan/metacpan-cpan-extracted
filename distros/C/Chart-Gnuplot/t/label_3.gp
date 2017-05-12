set terminal postscript enhanced color
set output "temp.ps"
set label "Test label 1" at 2, -0.3 offset 1.5, 0 noenhanced point pointtype 5 pointsize 3 linecolor rgb "blue"
set label "Test label 2" at -2, 0.3 noenhanced point pointtype 64 pointsize 2

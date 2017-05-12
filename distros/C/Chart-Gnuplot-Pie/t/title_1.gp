set terminal postscript enhanced color
set output "temp.ps"
unset border
unset tics
unset key
unset colorbox
set parametric
set xyplane at 0
set urange [0:1]
set vrange [0:1]
set zrange [-1:1]
set cbrange [-1:1]
set title "Testing title" noenhanced

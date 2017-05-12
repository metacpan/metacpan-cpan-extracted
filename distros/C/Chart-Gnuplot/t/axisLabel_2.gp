set terminal postscript enhanced color
set output "temp.ps"
set xlabel "My axis label in {/Symbol-Oblique greek}" offset 3,2 font "Courier, 30" textcolor rgb "pink"
set ylabel "Rotated 80 deg" noenhanced rotate by 80

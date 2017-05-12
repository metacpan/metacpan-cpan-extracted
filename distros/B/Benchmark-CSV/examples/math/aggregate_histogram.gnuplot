
#set xrange [0.0006:0.001]

set datafile separator ','

set style fill transparent solid 0.05

set key autotitle columnheader

set grid ytics lc rgb "#777777" lt 0 back

set boxwidth 0.9 relative

set terminal pngcairo enhanced rounded size 1300,768 font "Droid Sans"
set output 'math_histogram.png'

set xtics rotate by 45 right
#set terminal canvas standalone mousing size 800,600 rounded enhanced
#set output '/tmp/mathplot.html'
#set terminal dumb size 80,25

set style histogram gap 1
set style data histograms
set samples 10
plot for [c=2:14:2] \
  'out_hist.csv' using c:xticlabels(1)

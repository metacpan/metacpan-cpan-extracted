binwidth=0.000002

bin(x,width)=width*floor(x/width)

#set xrange [0.0006:0.001]

set datafile separator ','

set style fill transparent solid 0.05

set key autotitle columnheader

set grid ytics lc rgb "#777777" lt 0 back

set boxwidth 0.9 relative

set terminal pngcairo enhanced rounded size 1300,768 font "Droid Sans"
set output 'shuffle.png'

#set terminal canvas standalone mousing size 800,600 rounded enhanced
#set output '/tmp/mathplot.html'
#set terminal dumb size 80,25

plot for [c=1:7] \
  'out.csv' using (bin(column(c),binwidth)):(1.0) smooth freq with steps title columnhead(c);

#set samples 100
#plot for [c=1:7] \
#  '/tmp/out.csv' using c:(0.00005) smooth kdensity with steps title columnhead(c);

#plot for [c=1:7] \
#  '/tmp/out.csv' using c:(1.0) smooth cnormal with steps title columnhead(c);

#plot for [c=1:7] \
#  '/tmp/out.csv' using (bin(column(c),binwidth)):(1.0) smooth cnormal with steps title columnhead(c);

#plot for [c=1:7] \
#  '/tmp/out.csv' using (bin(column(c),binwidth)):(1.0) smooth cumulative with steps title columnhead(c);

#set style boxplot fraction 0.75 candlesticks nooutliers
#plot for [c=1:7] \
#  '/tmp/out.csv' using (c):c with boxplot title columnhead(c);

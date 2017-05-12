set terminal postscript enhanced color
set output "temp.ps"
set object rect from screen 0, screen 0 to screen 1, screen 1 fillcolor rgb "#a2a2ff" fillstyle solid 0.3 behind
set object rect from graph 0, graph 0 to graph 1, graph 1 fillcolor rgb "#FFDDDD" fillstyle solid 0.2 behind

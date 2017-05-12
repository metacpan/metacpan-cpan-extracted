#!/usr/bin/env guile -s

 Seems to buffer input...
!#
(use-modules (ice-9 readline))
(do ((line (readline "") (readline "")))
    ((eof-object? line))
    (display line) 
    (newline))
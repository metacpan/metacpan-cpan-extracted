#!/usr/bin/perl -w

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

# This is an Instance Script written to use the AllHandler CBB.
# You can use this script in a CGI environment, or even from the command line:
# if you do so, you can force the page name by passing an argument to process()
# (Note: This way will bypass the get_page_name method)

; $|++  # just to avoid buffering for this script

; warn '########## START CGI SCRIPT ##########'

; use TrackProcess
; my $CBB = TrackProcess->new()

; $CBB->process('page2')   # the argument forces page2 ...
# edit it with page1 and page3 to see the differences from the command line
# if you use it with the web server, please clear it i.e.:
# $CBB->process()

; warn '########## END CGI SCRIPT ##########'

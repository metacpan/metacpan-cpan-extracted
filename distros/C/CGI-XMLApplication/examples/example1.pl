#!/usr/bin/perl

# (c) 2001 ph15h (GPL)

# This is an example for a cgi script. such a script should not look
# different than this. If you put all functionality into the
# application class this script stays clean and causes no problems
# while debugging at all. 
#
# the global structure of the script is extremly easy:
# 1. load your application class.
# 2. create an instance of your class with new
# 3. call the  function.  
#
# if it is to hard for you to type all the code by your self,
# feel free to rename this script and modify it as needed.

use lib qw( ../blib/lib );
use example1;

my $script_class = new example1;
run $script_class;
# or do it this way:
# $script_class->run();



